import digitalocean, asyncdispatch, os

let tokenPath = "~/.digital_ocean_token.txt".expandTilde()

if existsFile(tokenPath):
  setToken(readFile(tokenPath))

  for key in waitFor getSSHKeys():
    echo (key.name, key.id)

  for image in waitFor getUserImages():
    echo (image.name, image.id, image.slug, image.regions)

  for image in waitFor getAllImages():
    echo (image.name, image.id, image.slug)

  for droplet in waitFor getAllDroplets():
    echo droplet.name

  for droplet in waitFor getDropletsByTag("gameserver"):
    echo droplet.name

  echo (waitFor getAccount()).email

  for action in waitFor getAllActions():
    echo action.`type`
