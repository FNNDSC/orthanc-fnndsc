# orthanc-fnndsc

An dockerized instance of Orthanc, with some FNNDSC-specific components.

This is essentially just a docker yml file that instantiates an orthanc-plugins instance in a container. Importantly, the json configuration file is tracked by this repo, and external to the container.

## Git it!

Simply do a 

```
git clone https://github.com/FNNDSC/orthanc-fnndsc.git
```

to check this repo out into your local filesystem.

## Run it!

Once checked out, run the docker with

```
docker-compose up -d
```

Note that you will of course need <tt>docker-compose</tt> for this. As of time of writing (i.e. Feb 2017), the latest ubuntu repos do **not** have the lastest version of docker, in particular if you install docker using <tt>apt install docker.io</tt> from standard repos, **you will not have the latest docker and will not have docker-compose!** 

There are many ways to install this. Google is your friend.

## Master branch

Two branches exist. The master branch creates a volume container for the Orthanc image database. This image database persists for the lifetime of the volume container. **When the volume container is shut down, the image database is lost**.

## Persistent DB branch

To have a persistent image database that lives across container lifetimes, check out the persistent-db branch once you have checked out the main repo:

```
git checkout persistent-db
```

and now run as above

```
docker-compose up -d
```

You will see a directory called <tt>db</tt> in the repo root that contains the Orthanc image database.



