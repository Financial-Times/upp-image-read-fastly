# UPP Image Read Fastly
__Contains fastly configuration for the resilient image read endpoint: prod-upp-image-read.ft.com.__

## DYN
* `prod-upp-image-read.ft.com` is a domain created in DYN: points to `nonssl.global.fastly.net`

## Backends
* EU s3 bucket:http://com.ft.imagepublish.prod.s3.amazonaws.com/
* US s3 bucket: http://com.ft.imagepublish.prod-us.s3.amazonaws.com/

## Features
* Geographic load balancing: fastly will route requests to either US or EU s3 bucket according to client location if both backends are healthy
* Health monitoring: fastly will check the health of each bucket every 10s and disable backend/bucket if unhealthy
	* If both aws regions are unhealthy it will default(route requests) to EU
	* Checks:
		* EU: HEAD http://com.ft.imagepublish.prod.s3.amazonaws.com/845323cc-864c-11e6-8897-2359a58ac7a5
		* US: HEAD http://com.ft.imagepublish.prod-us.s3.amazonaws.com/845323cc-864c-11e6-8897-2359a58ac7a5
* Missing image from bucket
	* For example if http://com.ft.imagepublish.prod.s3.amazonaws.com/845323cc-864c-11e6-8897-2359a58ac7a5 returns 403 which means the image is not available in the EU bucket it will be served from US http://com.ft.imagepublish.prod-us.s3.amazonaws.com/845323cc-864c-11e6-8897-2359a58ac7a5

## Deployment
Deployment is manual for now and done by uploading default.vcl to fastly and activating the new version.  

* Could be automated using https://github.com/Financial-Times/fastly-tools/

### Prerequisites
* Fastly account: ask #environments

### How to
* Create a git tag: `0.0.[fastly revision number]`
* Log in to fastly: https://app.fastly.com/#configure/service/2gNrEbKzPgIombbpKc48so
* Service name: `UPP Image Read prod`
* Go to VLC -> upload
* Hit activate to deploy the changes

