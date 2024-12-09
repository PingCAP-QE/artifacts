// It can not used standalone. we used it after we checkouted the source code, and mounted the ssh info volume.
import { NodeSSH, SSHExecOptions } from "npm:node-ssh@13.2.0";
import * as path from "jsr:@std/path@1.0.8";
import { parseArgs } from "jsr:@std/cli@^1.0.1/parse-args";
import * as yaml from "jsr:@std/yaml@1.0.5";
import * as colors from "jsr:@std/fmt@^1.0.3/colors";

interface CliArgs {
    sourcePath: string;
    envFile: string;
    scriptFile: string;
    component: string;
    boskos: BoskosOptions;
    sshInfoDir: string;
    releaseDir: string;
}

interface BoskosOptions {
    serverUrl: string;
    owner: string;
    type: string;
    timeout?: number;
}

interface buildOptions {
    sourcePath: string;
    remoteWorkspace: string;
    scriptFile: string;
    scriptArgs: string;
    component: string;
    envFile: string;
    releaseDir: string;
}

interface BoskosResource {
    type: string;
    name: string;
    state: string;
    owner: string;
    lastupdate: string;
    userdata?: Record<string, any>;
}

interface boskosAcquireParams {
    owner: string;
    type: string;
    state?: string;
    dest?: string;
    timeout?: number;
}

// define a boskos ctl class
class BoskosClient {
    private boskosServerUrl: string;

    // define methods: acquire, release, update
    constructor(boskosServerUrl: string) {
        this.boskosServerUrl = boskosServerUrl;
    }

    // acquire a resource from boskos server
    async acquire({ owner, type, state, dest, ...rest }: boskosAcquireParams) {
        const startTime = Date.now();
        const retryInterval = 5000; // 5 seconds between retries
        const timeout = rest.timeout || 600000; // 10 minutes

        while (Date.now() - startTime < timeout) {
            const url =
                `${this.boskosServerUrl}/acquire?owner=${owner}&type=${type}&state=${state}&dest=${dest}`;
            const response = await fetch(url, {
                method: "POST",
                body: JSON.stringify({}),
            });

            if (response.ok) {
                const data = await response.json();
                return data as BoskosResource;
            } else if (response.status === 404) {
                console.log(
                    `Resource not available, retrying in ${
                        retryInterval / 1000
                    } seconds...`,
                );
                await new Promise((resolve) =>
                    setTimeout(resolve, retryInterval)
                );
                continue;
            } else {
                console.log(response.statusText);
                throw new Error(
                    `Failed to acquire resource from Boskos server: ${response.statusText}`,
                );
            }
        }

        throw new Error(
            `Timeout after ${timeout / 1000} seconds waiting for resource`,
        );
    }

    // release a resource to boskos server
    async release(name: string, owner: string, dest = "free") {
        const url =
            `${this.boskosServerUrl}/release?owner=${owner}&name=${name}&dest=${dest}`;
        const response = await fetch(url, {
            method: "POST",
            body: JSON.stringify({}),
        });
        const data = await response.text();
        return data;
    }

    async heartbeat(name: string, owner: string, state: string) {
        const url =
            `${this.boskosServerUrl}/update?name=${name}&owner=${owner}&state=${state}`;
        const response = await fetch(url, {
            method: "POST",
            body: JSON.stringify({}),
        });
        const data = response.text();
        return data;
    }

    async lockAndDo(
        boskos: { owner: string; type: string; timeout?: number },
        deal: (resource: BoskosResource) => Promise<void>,
    ) {
        let needHearbeat = true;
        const heartbeat = async (resource: BoskosResource) => {
            while (needHearbeat) {
                await this.heartbeat(resource.name, boskos.owner, "busy");
                await new Promise((resolve) => setTimeout(resolve, 60000));
            }

            console.log("❤️ heartbeat stopped");
        };
        const resource = await this.acquire({
            ...boskos,
            state: "free",
            dest: "busy",
        });
        // parallel send the heartbeat to boskos server.
        await Promise.all([
            heartbeat(resource),
            deal(resource).finally(() => {
                console.log(
                    "🔓 release the drawin builder....",
                );
                needHearbeat = false;
                this.release(resource.name, boskos.owner);
            }),
        ]);
    }
}

async function sshExec(
    ssh: NodeSSH,
    command: string,
    args: string[],
    options: SSHExecOptions,
) {
    const ret = await ssh.exec(command, args, {
        ...options,
        stream: "both",
        onStdout(chunk) {
            console.log(
                chunk.toString().trimEnd().split("\n").map((line) =>
                    colors.bgBlue("[📡 STDOUT] ") + line
                ).join("\n"),
            );
        },
        onStderr(chunk) {
            console.error(
                chunk.toString().trimEnd().split("\n").map((line) =>
                    colors.bgYellow("[📡 STDERR] ") + line
                ).join("\n"),
            );
        },
    });
    if (ret.code !== 0) {
        throw new Error(`command run failed, exit code: ${ret.code}`);
    }
}
async function build(ssh: NodeSSH, options: buildOptions) {
    const remoteWorkspace = options.remoteWorkspace;
    const remoteCwd = path.join(
        remoteWorkspace,
        path.basename(options.sourcePath),
        options.component,
    );
    const remoteScriptFile = path.join(
        remoteWorkspace,
        path.basename(options.scriptFile),
    );
    const remoteEnvFile = path.join(
        remoteWorkspace,
        path.basename(options.envFile),
    );

    // 1. create a randon workspace dir in the remote host:
    console.info("🫧 create workspace dir");
    await ssh.mkdir(remoteWorkspace);

    // 2. copy the build script to the remote host
    console.info("🫧 copy script file to remote host");
    await ssh.putFile(options.scriptFile, remoteScriptFile);
    await ssh.exec("chmod", ["+x", remoteScriptFile]);

    // 3. copy the env file to the remote host
    console.info("🫧 copy env file to remote host");
    await ssh.putFile(options.envFile, remoteEnvFile);

    // 1.3 copy the local workspace to the remote host
    await copySourceToRemote(options.sourcePath, remoteWorkspace, ssh);

    // 4. run the build script remotely
    console.group("🚀 start building in remtoe host:");
    await sshExec(ssh, "bash", [
        "-lc",
        `source ${remoteEnvFile};${remoteScriptFile} ${options.scriptArgs}`,
    ], { cwd: remoteCwd });
    console.groupEnd();
    console.info("✅ build finished in remote host.");

    // 5. copy the artifacts from the mac hosts to the workspace `source`, we need deliver them internal firstly.
    console.info("🚢 copy artifacts from remote host to local host.");
    await Deno.mkdir(options.releaseDir, { recursive: true });
    await ssh.getDirectory(
        options.releaseDir,
        path.join(remoteCwd, options.releaseDir),
        { recursive: true },
    );
    console.info("✅ copied done.");
}

async function copySourceToRemote(
    sourcePath: string,
    remoteWorkspace: string,
    ssh: NodeSSH,
) {
    // archive the source dir to a tar file in local
    const tarFile = path.join("/tmp", "source.tar.gz");
    const tarRet = await new Deno.Command("tar", {
        args: ["-czf", tarFile, "-C", sourcePath, "."],
    }).output();
    if (!tarRet.success) {
        console.error(new TextDecoder().decode(tarRet.stderr));
        throw new Error("tar failed");
    }
    console.debug(tarRet.stdout.toString());
    const remoteTarFile = path.join(
        remoteWorkspace,
        path.basename(tarFile),
    );
    // upload the tar file to the remote host
    await ssh.putFile(tarFile, remoteTarFile);

    // untar the tar file in remote
    await ssh.mkdir(
        path.join(remoteWorkspace, path.basename(sourcePath)),
    );
    await ssh.exec("tar", [
        "-xzf",
        remoteTarFile,
        "-C",
        path.join(remoteWorkspace, path.basename(sourcePath)),
    ], { stream: "both" }).then((ret) => {
        if (ret.code !== 0) {
            console.error(ret.stderr.toString());
            throw new Error("tar failed");
        }
        return ret;
    });

    // remove the tar file in remote
    await ssh.exec("rm", [remoteTarFile]);
    // remove the tar file in local
    await Deno.remove(tarFile);
}

function getResourceUserData(resourceName: string, sshInfoFolder: string) {
    // read the host.yaml: host, workspace
    // read the private key, user, username

    // juge the ssh info folder exist or not, if not then throw error.
    const ret = Deno.statSync(sshInfoFolder);
    if (!ret.isDirectory) {
        throw new Error("ssh info folder not exist");
    }

    // read the username.
    const username = Deno.readTextFileSync(
        path.join(sshInfoFolder, "username"),
    );
    // read the private key
    const privateKey = Deno.readTextFileSync(
        path.join(sshInfoFolder, "id_rsa"),
    );
    // read and parse the hosts informations from hosts.yaml file:
    const hostsInfos = Deno.readTextFileSync(
        path.join(sshInfoFolder, "hosts.yaml"),
    );
    const hosts = yaml.parse(hostsInfos) as Record<
        string,
        { host: string; config: { workspace_dir: string } }
    >;
    const hostInfo = hosts[resourceName];

    return {
        config: hostInfo.config,
        ssh_host: hostInfo.host,
        ssh_port: 22,
        ssh_user: username,
        privateKey: privateKey,
    };
}

async function main(
    {
        sourcePath,
        envFile,
        scriptFile,
        component,
        boskos,
        sshInfoDir,
        releaseDir,
    }: CliArgs,
) {
    const boskosClient = new BoskosClient(boskos.serverUrl);
    await boskosClient.lockAndDo(boskos, async (resource) => {
        const userData = getResourceUserData(resource.name, sshInfoDir);
        const ssh = new NodeSSH();
        console.info("🚩💻 remote building host is ", resource.name);
        await ssh.connect({
            host: userData.ssh_host,
            port: userData.ssh_port,
            username: userData.ssh_user,
            privateKey: userData.privateKey,
        });
        console.info("🫧 prepare to build");
        const remoteWorkspace = path.join(
            userData.config.workspace_dir,
            boskos.owner,
        );
        const buildOptions = {
            scriptFile: scriptFile,
            scriptArgs: `-b -a -w ${releaseDir}`,
            envFile,
            sourcePath,
            component,
            releaseDir,
            remoteWorkspace: remoteWorkspace,
        };
        console.dir({ buildOptions });
        await build(ssh, buildOptions).finally(async () => {
            // clean the remote workspace.
            await ssh.exec("rm", ["-rvf", remoteWorkspace]);
            ssh.dispose();
        });
        console.info("🎉🎉🎉 all done");
    });
}

// deno run --allow-all <script> --sourcePath=<xxx> --envFile=<xxx> --scriptFile=<xxx> --component=<xxx> --boskos.serverUrl=<xxx> --boskos.type=<xxx> --boskos.owner=<xxx> --sshInfoDir=<xxx> --releaseDir=<xxx>
const args = parseArgs(Deno.args) as CliArgs;
await main(args);
