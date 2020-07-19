chmod 400 /root/HybridCLoud2/tls_key.pem

scp -i   /root/HybridCLoud2/tls_key.pem -o "StrictHostKeyChecking no" /root/HybridCLoud2/test.sh  ec2-user@$(cat /root/HybridCLoud2/ec2_link.txt):/home/ec2-user/
scp -i   /root/HybridCLoud2/tls_key.pem -o "StrictHostKeyChecking no" /root/HybridCLoud2/cloudfront_link.txt  ec2-user@$(cat /root/HybridCLoud2/ec2_link.txt):/home/ec2-user/

ssh -tt -i /root/HybridCLoud2/tls_key.pem -o "StrictHostKeyChecking no" ec2-user@$(cat /root/HybridCLoud2/ec2_link.txt) "chmod 777 test.sh; ./test.sh"

