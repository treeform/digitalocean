# DigitalOcean nim api wrapper

Wraps many of the API endpoints that digital ocean has. If you need more of them wrapped feel free to open up an issue or add a pull request.


## Imports
This library really worls well with [ssh](https://github.com/treeform/ssh) and I also use [print](https://github.com/treeform/print).

```nim
import digitalocean, ssh, print
```

## Create a new droplet

I created this wrapper to manage servers based on demand.
I use this to spin up servers when they are needed and spin them down
when they are not.

```nim
var droplet = await createDroplet(
 name = "alpine1",
 region = "sfo2",
 size = "s-1vcpu-1gb",
 image = 37823650,
 ssh_keys = @[10000],
 backups = false,
 ipv6 = false,
 private_networking = false,
 user_data = "",
 monitoring = false,
 volumes = @[],
 tags = @["test"],
)
```

Wait for the droplet to become active:

```nim
while droplet.status == "new":
 print droplet.status
 droplet = await getDroplet(d.id)
 sleep(1000)
print dropletd.status
```

After a droplet is `active` it is ready to start doing things.
I is use my [ssh library](https://github.com/treeform/ssh) to log into the computer to set it up. Setup is some thing like this:

```nim
import ssh
var server = newSSH(user & "@" & droplet.publicIp)
server.command("apk install ...")
server.writeFile("/etc/someconfig", "{...}")
server.exit()
```

Then delete the droplet when I am done:

```
await deleteDroplet(droplet.id)
```

## Get all SSH keys

I highly recommend using SSH keys for everything, never use server passwords. You can list the keys and the IDs you need for droplet creation with this:

```nim
for key in await getAllSSHKeys():
 echo key.name, " ", key.id
```

## Get all User images

I create an image that is a base setup for all my server. You can use the images you have from here. You need the `image.id` and `image.regions` to match when creating a droplet.

```
for image in await getAllUserImages():
 print image.name, image.id, image.slug, image.regions
```

You can also list public images which there are many of:

```
for image in await getAllImages():
 print image.name, image.id, image.slug, image.regions
```

## Get Droplets

You can see all the droplets you have here:

```nim
for droplet in await getDropletsByTag("gameserver"):
 print droplet.name
```

But I think it’s more useful to tag your droplets and look at the by tag. Once you have many droplets the list becomes cluttered.

```nim
for droplet in await getDropletsByTag("gameserver"):
 print droplet.name
```

## Get your account information

You can get your account information.

```nim
print await getAccount()
```

You can also get recent actions that happened like which servers got started or stopped:

```nim
for action in await getAllActions():
 print action.`type`
```




