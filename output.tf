# Display the load balancer DNS name
output "alb_dns_name" {
    value = "DNS name of the Applicaton Load Balancer ${aws_lb.LabVPCALB.dns_name}"
}