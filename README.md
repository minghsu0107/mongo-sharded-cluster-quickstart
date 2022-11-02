# MongoDB Sharded Cluster Quickstart
Set up a minimal MongoDB sharded cluster with a replication factor of 2 with docker-compose (only for development environment).

### Components

- Config Server (3-member replica set): `config01`,`config02`,`config03`
- 3 Shards (each a 2 member replica set):
	- `shard01a`,`shard01b`
	- `shard02a`,`shard02b`
	- `shard03a`,`shard03b`
- 1 Router (mongos): `router`

### Initialization
```bash
docker-compose up -d
```

Initialize the config server, shards, and router:
```bash
sh init.sh
```

This script has a `sleep 20` to wait for the config server and shards to elect the primaries of their replica sets respectively before initializing the router.

Create the first user `admin` on database `admin` and verify the status of the sharded cluster:

```bash
docker-compose exec -it router mongosh --host localhost --port 27017
mongos> admin = db.getSiblingDB("admin")
mongos> admin.createUser(
  {
    user: "admin",
    pwd:  "mypass",
    roles: [ 
      { role: "userAdminAnyDatabase", db: "admin" },
      { role: "clusterAdmin", db: "admin" }
    ]
  }
)
mongos> admin.auth('admin', 'mypass')
mongos> sh.status()
shardingVersion
{
  _id: 1,
  minCompatibleVersion: 5,
  currentVersion: 6,
  clusterId: ObjectId("636276b5aabddd36d3cee9e6")
}
---
shards
[
  {
    _id: 'shard01',
    host: 'shard01/shard01a:27018,shard01b:27018',
    state: 1,
    topologyTime: Timestamp({ t: 1667397315, i: 4 })
  },
  {
    _id: 'shard02',
    host: 'shard02/shard02a:27019,shard02b:27019',
    state: 1,
    topologyTime: Timestamp({ t: 1667397315, i: 12 })
  },
  {
    _id: 'shard03',
    host: 'shard03/shard03a:27020,shard03b:27020',
    state: 1,
    topologyTime: Timestamp({ t: 1667397315, i: 17 })
  }
]
---
active mongoses
[ { '6.0.2': 1 } ]
---
autosplit
{ 'Currently enabled': 'yes' }
---
balancer
{
  'Currently enabled': 'yes',
  'Currently running': 'no',
  'Failed balancer rounds in last 5 attempts': 0,
  'Migration Results for the last 24 hours': { '247': 'Success' }
}
---
databases
[
  {
    database: { _id: 'config', primary: 'config', partitioned: true },
    collections: {
      'config.system.sessions': {
        shardKey: { _id: 1 },
        unique: false,
        balancing: true,
        chunkMetadata: [
          { shard: 'shard01', nChunks: 777 },
          { shard: 'shard02', nChunks: 124 },
          { shard: 'shard03', nChunks: 123 }
        ],
        chunks: [
          'too many chunks to print, use verbose if you want to force print'
        ],
        tags: []
      }
    }
  }
]
```
Test client connection with user authentication:
```bash
docker-compose exec -it router mongosh --host localhost --port 27017 -u admin -p mypass --authenticationDatabase "admin"
```
For programming clients, you can use the following connection string URI:
```
mongodb://admin:mypass@router:27017/?authSource=admin
```