# digitalocean
# Copyright treeform
# Wrapper for Digital Ocean HTTP Api.
import httpclient, asyncnet, asyncdispatch, ospaths, uri, tables, strutils
import json
import print


type
  DigitalOceanError = object of Exception

  Account* = ref object
    ## Information about your current account.
    droplet_limit*: int # The total number of Droplets current user or team may have active at one time.
    floating_ip_limit*: int # The total number of Floating IPs the current user or team may have.
    email*: string # The email address used by the current user to registered for DigitalOcean.
    uuid*: string # The unique universal identifier for the current user.
    email_verified*: bool # If true, the user has verified their account via email. False otherwise.
    status*: string # This value is one of "active", "warning" or "locked".
    status_message*: string # A human-readable message giving more details about the status of the account.

  Action* = ref object
    ## Actions are records of events that have occurred on the resources in your account. These can be things like rebooting a Droplet, or transferring an image to a new region.
    id*: int # A unique numeric ID that can be used to identify and reference an action.
    status*: string # The current status of the action. This can be "in-progress", "completed", or "errored".
    `type`*: string # This is the type of action that the object represents. For example, this could be "transfer" to represent the state of an image transfer action.
    started_at*: string # A time value given in ISO8601 combined date and time format that represents when the action was initiated.
    completed_at*: string # A time value given in ISO8601 combined date and time format that represents when the action was completed.
    resource_id*: int # A unique identifier for the resource that the action is associated with.
    resource_type*: string # The type of resource that the action is associated with.
    #region*: object # A full region object containing information about the region where the action occurred.
    region_slug*: string # A slug representing the region where the action occurred.

  NetworkInterface = object
    ip_address: string
    netmask: string
    gateway: string
    `type`: string

  Networks = object
    v4: seq[NetworkInterface]
    v6: seq[NetworkInterface]

  Droplet* = ref object
    ## A Droplet is a DigitalOcean virtual machine.
    id*: int # A unique identifier for each Droplet instance. This is automatically generated upon Droplet creation.
    name*: string # The human-readable name set for the Droplet instance.
    memory*: int # Memory of the Droplet in megabytes.
    vcpus*: int # The number of virtual CPUs.
    disk*: int # The size of the Droplet's disk in gigabytes.
    locked*: bool # A boolean value indicating whether the Droplet has been locked, preventing actions by users.
    created_at*: string # A time value given in ISO8601 combined date and time format that represents when the Droplet was created.
    status*: string # A status string indicating the state of the Droplet instance. This may be "new", "active", "off", or "archive".
    backup_ids*: seq[int] # An array of backup IDs of any backups that have been taken of the Droplet instance. Droplet backups are enabled at the time of the instance creation.
    snapshot_ids*: seq[int] # An array of snapshot IDs of any snapshots created from the Droplet instance.
    features*: seq[string] # An array of features enabled on this Droplet.
    #region*: object # The region that the Droplet instance is deployed in. When setting a region, the value should be the slug identifier for the region. When you query a Droplet, the entire region object will be returned.
    #image*: object # The base image used to create the Droplet instance. When setting an image, the value is set to the image id or slug. When querying the Droplet, the entire image object will be returned.
    #size*: object # The current size object describing the Droplet. When setting a size, the value is set to the size slug. When querying the Droplet, the entire size object will be returned. Note that the disk volume of a Droplet may not match the size's disk due to Droplet resize actions. The disk attribute on the Droplet should always be referenced.
    size_slug*: string # The unique slug identifier for the size of this Droplet.
    networks*: Networks # The details of the network that are configured for the Droplet instance. This is an object that contains keys for IPv4 and IPv6. The value of each of these is an array that contains objects describing an individual IP resource allocated to the Droplet. These will define attributes like the IP address, netmask, and gateway of the specific network depending on the type of network it is.
    #kernel*: object # The current kernel. This will initially be set to the kernel of the base image when the Droplet is created.
    #next_backup_window*: object # The details of the Droplet's backups feature, if backups are configured for the Droplet. This object contains keys for the start and end times of the window during which the backup will start.
    tags*: seq[string] # An array of Tags the Droplet has been tagged with.
    volume_ids*: seq[string] # A flat array including the unique identifier for each Block Storage volume attached to the Droplet.

  Image* = ref object
    id*: int # A unique number that can be used to identify and reference a specific image.
    name*: string # The display name that has been given to an image. This is what is shown in the control panel and is generally a descriptive title for the image in question.
    `type`*: string # The kind of image, describing the duration of how long the image is stored. This is either "snapshot", "backup", or "custom".
    distribution*: string # This attribute describes the base distribution used for this image. For custom images, this is user defined.
    slug*: string #string: A uniquely identifying string that is associated with each of the DigitalOcean-provided public images. These can be used to reference a public image as an alternative to the numeric id.
    public*: bool # This is a boolean value that indicates whether the image in question is public or not. An image that is public is available to all accounts. A non-public image is only accessible from your account.
    regions*: seq[string] # This attribute is an array of the regions that the image is available in. The regions are represented by their identifying slug values.
    created_at*: string # A time value given in ISO8601 combined date and time format that represents when the image was created.
    min_disk_size*: int # The minimum disk size in GB required for a Droplet to use this image.
    size_gigabytes*: float # The size of the image in gigabytes.
    description*: string # An optional free-form text field to describe an image.
    tags*: seq[string] # An array containing the names of the tags the image has been tagged with.
    status*: string # A status string indicating the state of a custom image. This may be "NEW", "available", "pending", or "deleted".
    error_message*: string # A string containing information about errors that may occur when importing a custom image.

  SSHKey* = ref object
    id*: int # This is a unique identification number for the key. This can be used to reference a specific SSH key when you wish to embed a key into a Droplet.
    fingerprint*: string # This attribute contains the fingerprint value that is generated from the public key. This is a unique identifier that will differentiate it from other keys using a format that SSH recognizes.
    public_key*: string # This attribute contains the entire public key string that was uploaded. This is what is embedded into the root user's authorized_keys file if you choose to include this SSH key during Droplet creation.
    name*: string # This is the human-readable display name for the given SSH key. This is used to easily identify the SSH keys when they are displayed.



proc publicIp*(droplet: Droplet): string =
  ## Given a droplet finds its public v4 ip_address in networks object
  for net in droplet.networks.v4:
    if net.`type` == "public":
      return net.ip_address


const apiEndpoint = "https://api.digitalocean.com"
var globalToken: string


proc encodePostBody(params: openarray[(string, string)]): string =
  var parts = newSeq[string]()
  for pair in params:
    parts.add(encodeUrl(pair[0]) & "=" & encodeUrl(pair[1]))
  parts.join("&")


proc encodeParams(url: string, params: openarray[(string, string)]): string =
  url & "?" & encodePostBody(params)


proc setToken*(token: string) =
  globalToken = token


proc getAccount*(): Future[Account] {.async.} =
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({"Authorization": "Bearer " & globalToken})
  let response = await client.get(apiEndpoint & "/v2/account")
  return to(parseJson(await response.body)["account"], Account)


proc getAllActions*(): Future[seq[Action]] {.async.} =
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({"Authorization": "Bearer " & globalToken})
  let response = await client.get(apiEndpoint & "/v2/actions")
  let json = parseJson(await response.body)
  var actions = newSeq[Action]()
  for accountJson in json["actions"]:
    actions.add(to(accountJson, Action))
  return actions


proc getAction*(actionId: int): Future[Action] {.async.} =
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({"Authorization": "Bearer " & globalToken})
  let response = await client.get(apiEndpoint & "/v2/actions/" & $actionId)
  return to(parseJson(await response.body)["action"], Action)


## Droplets

proc getAllDroplets*(page=1, per_page=100): Future[seq[Droplet]] {.async.} =
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({"Authorization": "Bearer " & globalToken})
  let response = await client.get(encodeParams(
    apiEndpoint & "/v2/droplets", {"page": $page, "per_page": $per_page}))
  let json = parseJson(await response.body)
  var droplets = newSeq[Droplet]()
  for dropletJson in json["droplets"]:
    droplets.add(to(dropletJson, Droplet))
  return droplets


proc getDropletsByTag*(tag: string, page=1, per_page=100): Future[seq[Droplet]] {.async.} =
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({"Authorization": "Bearer " & globalToken})
  let response = await client.get(encodeParams(
    apiEndpoint & "/v2/droplets", {"page": $page, "per_page": $per_page, "tag_name": tag}))
  let json = parseJson(await response.body)
  var droplets = newSeq[Droplet]()
  for dropletJson in json["droplets"]:
    droplets.add(to(dropletJson, Droplet))
  return droplets


proc getDroplet*(dropletId: int): Future[Droplet] {.async.} =
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({"Authorization": "Bearer " & globalToken})
  let response = await client.get(apiEndpoint & "/v2/droplets/" & $dropletId)
  let json = parseJson(await response.body)
  let droplets = newSeq[Droplet]()
  let dropletJson = json["droplet"]
  return to(dropletJson, Droplet)

const dropletSizes = [
  "s-1vcpu-1gb",
  "s-1vcpu-2gb",
  "s-1vcpu-3gb",
  "s-2vcpu-2gb",
  "s-3vcpu-1gb",
  "s-2vcpu-4gb",
  "s-4vcpu-8gb",
  "s-6vcpu-16gb",
  "s-8vcpu-32gb",
  "s-12vcpu-48gb",
  "s-16vcpu-64gb",
  "s-20vcpu-96gb",
  "s-24vcpu-128gb",
  "s-32vcpu-192gb"
]

proc createDroplet*(
  name: string, # The human-readable string you wish to use when displaying the Droplet name.
  region: string, # The unique slug identifier for the region that you wish to deploy in. true
  size: string, # The unique slug identifier for the size that you wish to select for this Droplet. true
  image: int, # if using an image ID), or String (if using a public image slug) The image ID of a public or private image, or the unique slug identifier for a public image. This image will be the base image for your Droplet.
  ssh_keys: seq[int], # An array containing the IDs or fingerprints of the SSH keys that you wish to embed in the Droplet's root account upon creation.
  backups: bool, # A boolean indicating whether automated backups should be enabled for the Droplet. Automated backups can only be enabled when the Droplet is created.
  ipv6: bool, # A boolean indicating whether IPv6 is enabled on the Droplet.
  private_networking: bool, # A boolean indicating whether private networking is enabled for the Droplet. Private networking is currently only available in certain regions.
  user_data: string, # A string containing 'user data' which may be used to configure the Droplet on first boot, often a 'cloud-config' file or Bash script. It must be plain text and may not exceed 64 KiB in size.
  monitoring: bool, # A boolean indicating whether to install the DigitalOcean agent for monitoring.
  volumes: seq[string], # A flat array including the unique string identifier for each Block Storage volume to be attached to the Droplet. At the moment a volume can only be attached to a single Droplet.
  tags: seq[string], # A flat array of tag names as strings to apply to the Droplet after it is created. Tag names can either be existing or new tags.
): Future[Droplet] {.async.} =
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({
    "Authorization": "Bearer " & globalToken,
    "Content-Type": "application/json"
  })
  let bodyStr = $(%*{
    "name": name,
    "region": region,
    "size": size,
    "image": image,
    "ssh_keys": ssh_keys,
    "backups": backups,
    "ipv6": ipv6,
    "private_networking": private_networking,
    "user_data": user_data,
    "monitoring": monitoring,
    "volumes": volumes,
    "tags": tags
  })
  let response = await client.post(apiEndpoint & "/v2/droplets", body = bodyStr)
  let json = parseJson(await response.body)
  if "id" in json:
    raise newException(DigitalOceanError, json["id"].getStr() & ": " & json["message"].getStr())
  let droplets = newSeq[Droplet]()
  let dropletJson = json["droplet"]
  return to(dropletJson, Droplet)


proc deleteDroplet*(dropletId: int) {.async.} =
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({"Authorization": "Bearer " & globalToken})
  let response = await client.request(apiEndpoint & "/v2/droplets/" & $dropletId, httpMethod = HttpDelete)
  if response.status != "204 No Content":
    raise newException(DigitalOceanError, "Droplet was not deleted")

## Images

proc getImages*(url: string): Future[seq[Image]] {.async.} =
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({"Authorization": "Bearer " & globalToken})
  let response = await client.get(url)
  let json = parseJson(await response.body)
  var images = newSeq[Image]()
  for dropletJson in json["images"]:
    images.add(to(dropletJson, Image))
  return images

proc getAllImages*(page=1, per_page=100): Future[seq[Image]] {.async.} =
  return await getImages(encodeParams(apiEndpoint & "/v2/images", {"page": $page, "per_page": $per_page}))

proc getDistributionImages*(page=1, per_page=100): Future[seq[Image]] {.async.} =
  return await getImages(encodeParams(apiEndpoint & "/v2/images", {"page": $page, "per_page": $per_page, "type": "distribution"}))

proc getApplicationImages*(page=1, per_page=100): Future[seq[Image]] {.async.} =
  return await getImages(encodeParams(apiEndpoint & "/v2/images", {"page": $page, "per_page": $per_page, "type": "application"}))

proc getUserImages*(page=1, per_page=100): Future[seq[Image]] {.async.} =
  return await getImages(encodeParams(apiEndpoint & "/v2/images", {"page": $page, "per_page": $per_page, "private": "true"}))

proc getImagesByTag*(tag: string, page=1, per_page=100): Future[seq[Image]] {.async.} =
  return await getImages(encodeParams(apiEndpoint & "/v2/images", {"page": $page, "per_page": $per_page, "tag": tag}))


## SSH Keys

proc getSSHKeys*(page=1, per_page=100): Future[seq[SSHKey]] {.async.} =
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({"Authorization": "Bearer " & globalToken})
  let response = await client.get(encodeParams(
    apiEndpoint & "/v2/account/keys", {"page": $page, "per_page": $per_page}))
  let json = parseJson(await response.body)
  var keys = newSeq[SSHKey]()
  for keysJson in json["ssh_keys"]:
    keys.add(to(keysJson, SSHKey))
  return keys


