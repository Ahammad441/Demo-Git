# create vpc name with stage
# Data search available zones and provides to subnets and give print in output.terraform
# Which reagion Data serches for availabilty zones / ap-southeast-1 / why
# why / because it lloks folder .aws / credentials and configure ( region-id picks )
data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_vpc" "vpc" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "stage-vpc2",
    Terraform = "True",
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "stage-igw"
  }

  depends_on = [
    aws_vpc.vpc,
  ]
}




# aws_internet_gateway.igw.arn

resource "aws_subnet" "public" {

  count = length(data.aws_availability_zones.available.names)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.pub_cidr,count.index)
  map_public_ip_on_launch = "true"
  availability_zone = element(data.aws_availability_zones.available.names,count.index)

  tags = {
    Name = "Stage-Public-${count.index+1}-Subnet"
  }
}

resource "aws_subnet" "private" {

  count = length(data.aws_availability_zones.available.names)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.private_cidr,count.index)
  # map_public_ip_on_launch = "flase"
  availability_zone = element(data.aws_availability_zones.available.names,count.index)

  tags = {
    Name = "Stage-Private-${count.index+1}-Subnet"
  }
}


resource "aws_subnet" "data" {

  count = length(data.aws_availability_zones.available.names)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.data_cidr,count.index)
  # map_public_ip_on_launch = "false"
  availability_zone = element(data.aws_availability_zones.available.names,count.index)

  tags = {
    Name = "Stage-Data-${count.index+1}-Subnet"
  }
}


resource "aws_eip" "eip" {
  
  vpc = true

  tags ={
  Name = "Stage-EIP"
  }
}


resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "Stage-NATgw"
  }

 depends_on = [
aws_eip.eip
 ]
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }



  tags = {
    Name = "Stage-Public-Route"
  }
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }



  tags = {
    Name = "Stage-private-Route"
  }
}


resource "aws_route_table_association" "public" {
  count = length (aws_subnet.public[*].id)
  subnet_id      = element(aws_subnet.public[*].id,count.index)
  route_table_id = aws_route_table.public.id
}



resource "aws_route_table_association" "private" {
  count = length (aws_subnet.public[*].id)
  subnet_id      = element(aws_subnet.private[*].id,count.index)
  route_table_id = aws_route_table.private.id

}

resource "aws_route_table_association" "data" {
  count = length (aws_subnet.public[*].id)
  subnet_id      = element(aws_subnet.data[*].id,count.index)
  route_table_id = aws_route_table.private.id

}



# # To ensure proper ordering, it is recommended to add an explicit dependency
  # # on the Internet Gateway for the VPC.
  # depends_on = [aws_internet_gateway.example]

#create a vpc - region
#cidr

#create subnet
#public
#public1
#cidr
#az
#auto assign

# create nat gw for public
