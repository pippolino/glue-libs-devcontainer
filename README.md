# AWS Glue Local Development with SSO Support on Amazon Linux 2023

This repository provides a streamlined setup for running AWS Glue ETL libraries locally with support for AWS SSO, based on Amazon Linux 2023, in a **DevContainer**. It resolves common challenges faced when configuring AWS Glue locally, as discussed in various resources.

## Key Features

- **DevContainer Integration**: Fully configured for use with Visual Studio Code or compatible tools.
- **AWS SSO Support**: Properly handles AWS SSO credential management to facilitate seamless local testing.
- **Jupyter Environment**: Preconfigured Jupyter server for interactive development.
- **Spark Configuration**: Includes PySpark setup for ETL development.
- **References and Improvements**: Inspired by discussions and community solutions, such as:
  - [Reddit discussion on AWS Glue with AWS SSO](https://www.reddit.com/r/aws/comments/17674iv/aws_glue_locally_with_aws_sso/)
  - [AWS SDK Credentials Profile documentation](https://docs.aws.amazon.com/sdk-for-java/latest/developer-guide/credentials-profiles.html)
  - [Glue Libs with SSO by Jerdoe](https://github.com/jerdoe/glue_libs_sso)

## Getting Started

### Prerequisites

- Visual Studio Code installed on your local machine.
- Docker installed and running.
- AWS SSO configuration in your `~/.aws/credentials` or environment variables.
- Familiarity with AWS Glue and ETL processes.

### Using the DevContainer

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd <repository-folder>
   ```

2. Open the repository in Visual Studio Code.

3. When prompted, open the folder in the DevContainer. Alternatively, you can manually rebuild the container:
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac) to open the Command Palette.
   - Select **Remote-Containers: Rebuild and Reopen in Container**.

4. The DevContainer will start and initialize:
   - AWS credentials will be mounted into the container.
   - The Jupyter server will be started automatically.

### Accessing JupyterLab

Once the DevContainer is running, JupyterLab will be accessible at `http://localhost:8889`. It is preconfigured with all necessary libraries and paths for AWS Glue development.

### Key Configuration Details

- **DevContainer**: Configuration is defined in `devcontainer.json` for a seamless setup.
- **Jupyter**: Automatically starts on container launch via the `postStartCommand` script.
- **Spark**: Configured with paths to `PyGlue.zip` and `py4j` for full Glue functionality.
- **Network Ports**:
  - `4040`: Spark UI
  - `18080`: Spark History Server
  - `8998`: Livy Server
  - `8889`: JupyterLab

### Customizing the Environment

Modify the `devcontainer.json` and `Dockerfile` to customize dependencies and environment configurations.

## Contributing

Feel free to open issues or submit pull requests to improve this repository.
