
set -e


sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu


sudo apt-get autoremove -y
sudo apt-get clean