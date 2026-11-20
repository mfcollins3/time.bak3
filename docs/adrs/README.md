# Architectural Decision Records

This directory contains the Architectural Decision Records (ADRs) for Naked
Time. Each ADR records an important architectural decision, along with its
context and consequences.

| ADR | Title | Status | Description |
| --- | ----- | ------ | ----------- |
| [0001](0001-use-aspire-for-development-and-testing.md) | Use Aspire to Orchestrate Naked Time for Local Development and Testing | Accepted | Use Aspire and a TypeScript AppHost to run, connect, observe, and test Naked Time's components locally, with a path to Azure deployment. |
| [0002](0002-deploy-web-to-azure-container-apps.md) | Deploy the Web Application to Azure Container Apps with Aspire and GitHub Actions | Accepted | GitHub Actions builds a cached, multi-platform image; Aspire deploys it to Azure Container Apps with Entra ID database authentication and a migration job. |
