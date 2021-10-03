# Set up custom domains for Azure services using Azure Bicep

Setting up a custom domain name for an Azure service using infrastructure-as-code can be challenging. Should you even attempt to do it? There is no single right answer to that question except for: "it depends."

If you are in a situation where you do want to set up a custom domain during your infrastructure setup with Azure Bicep, you can use the examples in this repository as inspiration of how it can be achieved.

## Provided examples

- [Azure Static Web Apps](./azure-static-web-apps/)
  - This example demonstrates how to set up an (empty) Static Web App with a custom domain
- [Azure Function Apps](./azure-function-apps/)
  - This example demonstrates how to set up a Function App with a custom domain
- [Azure CDN endpoint](./azure-cdn-endpoint/)
  - This examples demonstrates how to set up a CDN Profile and Endpoint together with a Storage Account origin, and add a custom domain to the CDN Endpoint resource
