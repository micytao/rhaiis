# Setup Instructions

## Hugging Face Token Configuration

To properly configure your Hugging Face token for this project:

### 1. Local Development

1. Your actual Hugging Face token has been moved to `hf_token.txt` (which is git-ignored)
2. Before deploying, you need to update the secret files with your actual token

### 2. Updating Secrets for Deployment

Replace the placeholder `<YOUR_HUGGINGFACE_TOKEN>` in the following files with your actual token:

- `kustomize/base/secret.yaml`
- `rhaiis-deployment.yml`

You can use the token from `hf_token.txt` or get a new one from [Hugging Face Settings](https://huggingface.co/settings/tokens).

### 3. Automated Setup (Optional)

You can create a simple script to replace the placeholder:

```bash
#!/bin/bash
# setup-secrets.sh
HF_TOKEN=$(cat hf_token.txt)
sed -i.bak "s/<YOUR_HUGGINGFACE_TOKEN>/$HF_TOKEN/g" kustomize/base/secret.yaml
sed -i.bak "s/<YOUR_HUGGINGFACE_TOKEN>/$HF_TOKEN/g" rhaiis-deployment.yml
echo "Secrets updated with HF token"
```

### 4. For Production

For production deployments, consider using:
- Kubernetes secrets created via `kubectl create secret`
- External secret management systems (Vault, AWS Secrets Manager, etc.)
- CI/CD pipeline secret injection

### 5. Security Notes

- Never commit your actual HF token to git
- The `hf_token.txt` file is automatically ignored by git
- Always use placeholders in committed files
- Rotate your tokens regularly
