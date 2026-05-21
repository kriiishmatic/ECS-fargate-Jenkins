locals{
    ami_id = data.aws_ami.jenkins_ami.id
    common_tags = {
        Project = var.project
        Environment = var.environment
        Terraform = "true"
    }
}