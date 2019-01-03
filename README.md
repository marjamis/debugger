# debugger
This container image contains all the usual tools for testing networking while also running both sshd and nginx processes for easy access to poke around within the container. It also has an inbuilt script to run a tcpdump within the containers/Task/Pod's network namespace and then offload it to an S3 bucket for access from outside the container.

**Note:** The nginx webserver listens on port 80 and sshd listens on port 8022 within the container.

## Configuration
### Environment Variables
A full list of available environment variables:

| Name | Allowed Values | Description |
| --- | --- | --- |
| TCPDUMP | true/false | Enables the tcpdumping mechanism. Default is false. |
| BUCKET | The bucket name | If the TCPDUMP is set to true this will be the bucket that the tcpdumps are put into |

## HowTo's / Samples
### Using the inbuilt tcpdump capturing and pushing to S3
By default, this will generate a pcap file every 30seconds for 300 times and have this offloaded to the specified bucket. Due to it running the AWS CLI it will require the normal SDK permissions for the call out to S3. An example command is:
```bash
docker run -dit --name debugger-tcpdump -v ~/.aws/:/root/.aws/ -e BUCKET={bucket} -e TCPDUMP=true -p 8023:80 -p 8022:8022 debugger
```

### Sample Fargate Task Definition
```json
{
  "executionRoleArn": "arn:aws:iam::{account}:role/{ecsExecutionRole}",
  "containerDefinitions": [
    {
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/testing",
          "awslogs-region": "us-west-2",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "portMappings": [
        {
          "hostPort": 8022,
          "protocol": "tcp",
          "containerPort": 8022
        },
        {
          "hostPort": 80,
          "protocol": "tcp",
          "containerPort": 80
        }
      ],
      "cpu": 0,
      "memory": 256,
      "memoryReservation": 128,
      "image": "{image}",
      "essential": true,
      "name": "accessContainer"
    }
  ],
  "memory": "512",
  "taskRoleArn": "arn:aws:iam::{account}:role/{taskRole}",
  "compatibilities": [
    "EC2",
    "FARGATE"
  ],
  "family": "testing",
  "networkMode": "awsvpc",
  "cpu": "256"
}
```
