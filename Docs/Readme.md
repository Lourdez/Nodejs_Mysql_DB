# Deployment of Node.js application with a MySQL database, incorporating a CI/CD pipeline on AWS using Terraform
The project entails the containerization of a Node.js application using Docker, followed by deployment on an AWS EC2 instance. The application relies on an RDS MySQL database. The infrastructure provisioning is accomplished using Terraform. Additionally, a CI/CD pipeline is established with AWS CodeDeploy and AWS CodePipeline . To ensure effective monitoring, aCloud watch is ensured.
# The project flow diagram 

![Untitled Diagram](https://github.com/Lourdez/Terraform-IAC-HCL/assets/54675124/2ea188da-e53d-4638-9604-4c72a7e5d1a2)

# Steps in brief
+ create necessary resources mentioned in environment.tf
+ Clone the the repo in to the developer machine and make changes with mysql RDS by creating a new databases and new table
+ configre AWS CLI
+ Push the code into S3 bucket
+ create a Code Deploy and deployment group which will connect deployment ec2 machine
+ create the pipeline 
+ create cloud watch alarm
