**Application**

[Koel](https://github.com/phanan/koel)

**Description**

Koel (also stylized as koel, with a lowercase k) is a simple web-based personal audio streaming service written in Vue on the client side and Laravel on the server side. Targeting web developers, Koel embraces some of the more modern web technologies – flexbox, audio, and drag-and-drop API to name a few – to do its job.

**Build notes**

Latest GitHub release of Koel.

**Usage**
```
docker run -d \
    -p 8050:8050 \
    -p 8060:8060 \
    --name=<container name> \
    -v <path for media files>:/media \
    -v <path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e PUID=<uid for user> \
    -e PGID=<gid for user> \
    binhex/arch-koel
```

Please replace all user variables in the above command defined by <> with the correct values.

**Access application**<br>

`http://<host ip>:8050`

or

`https://<host ip>:8060`

**Example**
```
docker run -d \
    -p 8050:8050 \
    -p 8060:8060 \
    --name=koel \
    -v /media/music:/media \
    -v /apps/docker/koel/config:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-koel
```

**Notes**<br>

User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:-

```
id <username>
```

Default username for the webui is "admin@example.com", password is "admin"
___
If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Support forum](http://lime-technology.com/forum/index.php?topic=45820.0)