# PyCharm Integration

PyCharm allows to set up a SSH connection to deploy your code on the server:

- Go to `Settings > Tools > SSH Configurations` and create a new connection using the credentials provided to you via mail. The server uses the default SSH port 22.
- Go to `Settings > Build, Execution, Deployment > Deployment`. Choose `SFTP` as the connection type and select the connection you created in the previous step. Set your home path to `/home/<username>`. The option `Mappings` allows to configure where your local project is uploaded to on the server. For instance, setting `Deployment Path` to `projects/thesis` will upload your project to `/home/<username>/projects/thesis`. Adding excluded paths allows to exclude files from the upload. For instance, adding `.venv` will exclude the virtual environment from the upload.
