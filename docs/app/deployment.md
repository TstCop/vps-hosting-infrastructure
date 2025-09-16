# Deployment Instructions

This document provides instructions for deploying the infrastructure project for managing Vagrant and KVM for a VPS hosting company.

## Prerequisites

Before deploying the project, ensure that you have the following installed:

- **Vagrant**: Version 2.2.0 or higher
- **KVM**: Ensure that KVM is installed and configured on your server
- **Libvirt**: Required for managing KVM instances
- **Node.js**: Version 14.x or higher
- **npm**: Version 6.x or higher

## Deployment Steps

1. **Clone the Repository**

   Clone the repository to your local machine or server:

   ```
   git clone https://github.com/your-repo/vps-hosting-infrastructure.git
   cd vps-hosting-infrastructure
   ```

2. **Install Dependencies**

   Navigate to the project directory and install the required Node.js dependencies:

   ```
   npm install
   ```

3. **Configure Environment Variables**

   Create a `.env` file in the root directory and set the necessary environment variables. You can use the provided example:

   ```
   DATABASE_URL=your_database_url
   KVM_HOST=your_kvm_host
   ```

4. **Set Up Database**

   Ensure that your database is set up according to the configuration in `config/database.yaml`. Run any necessary migrations or seeders.

5. **Provision VMs**

   Navigate to the client directories and provision the VMs using Vagrant:

   ```
   cd clients/client-001
   vagrant up
   ```

   Repeat this step for each client directory as needed.

6. **Start the API Server**

   Start the API server by running the following command in the root directory:

   ```
   npm start
   ```

7. **Access the API**

   The API should now be running. You can access it at `http://localhost:3000` (or the configured port).

## Additional Notes

- Ensure that your firewall settings allow traffic on the necessary ports.
- For KVM management, you may need to configure user permissions to allow access to the KVM resources.
- Refer to the specific client README files for additional setup instructions related to each client's environment.

## Troubleshooting

If you encounter issues during deployment, check the following:

- Ensure all prerequisites are installed and configured correctly.
- Review the logs for any error messages.
- Consult the documentation for Vagrant and KVM for further assistance.

---

*This document will be updated as necessary to reflect changes in the deployment process.*