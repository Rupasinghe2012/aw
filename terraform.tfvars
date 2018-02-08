#Add your AWS Keys here 
access_key = ""
secret_key = ""



#Select Region

region = "us-east-1" 

#VPC related vars
vpc_name = "MMB"
cidr_block = "10.0.0.0/16"
public_ranges = "10.0.0.0/20"
private_ranges = "10.0.48.0/20"

#Define Instance Type

instance_type = "t2.micro"

amis {
	ap-northeast-1 =  "ami-571e3c30"
	ap-northeast-2 =  "ami-97cb19f9"
	ap-south-1 =  "ami-11f0837e"
	ap-southeast-1 =  "ami-30318f53"
	ap-southeast-2 =  "ami-24959b47"
	ca-central-1 =  "ami-daeb57be"
	eu-central-1 =  "ami-7cbc6e13"
	eu-west-1 =  "ami-0d063c6b"
	eu-west-2 =  "ami-c22236a6"
	sa-east-1 =  "ami-864f2dea"
	us-east-1 =  "ami-97785bed"
	us-east-2 =  "ami-9cbf9bf9"
	us-west-1 =  "ami-7c280d1c"
	us-west-2 =  "ami-0c2aba6c"
}