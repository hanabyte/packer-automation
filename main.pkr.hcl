packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

packer {
  required_plugins {
    vagrant = {
      version = "~> 1"
      source = "github.com/hashicorp/vagrant"
    }
  }
}  

source "amazon-ebs" "ubuntu" {
  ami_name      = "packer-ubuntu-aws-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami    = "ami-07d9b9ddc6cd8dd30"
  ssh_username  = "ubuntu"
}
  

build {
  sources = [
        "source.amazon-ebs.ubuntu"
    ]

  provisioner "file"{
    source      = "script.sh"  
    destination = "/tmp/script.sh"
    }

  provisioner "shell"{
    inline = [
            "chmod +x /tmp/script.sh",
            "/tmp/script.sh"
        ]
    }
}