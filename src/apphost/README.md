# Aspire AppHost

This directory contains the source code for the [Aspire](https://aspire.dev)
AppHost for the Naked Time product. Aspire is a code-first tool for composing
software programs with the resources that they need and running them locally.
The AppHost is a code-first specification of what software components make up
the Naked Time product and what resources they need to run. The AppHost will
build the Naked Time programs, download and run the services that they need,
and then run the Naked Time programs and link them together with the resources
to get Naked Time running locally on the developer's computer.

The main file of interest is [`apphost.mts`](apphost.mts). This is the AppHost
specification.

## Starting the AppHost

To start the AppHost, use the `run.sh` or `Run-Time.ps1` scripts from the root
directory of the Naked Time repository. After the AppHost starts, it will
display the URL of the [Aspire Dashboard](https://aspire.dev/dashboard/) that
you can use to see all of the executing components and obtain the URLs to use
to access the web applications, APIs, and services.
