	# k8s production EU (eu-west-1) backend definition
	# 6a70679a-fd9b-4d64-9bec-2d340fb75021
	# https://github.com/Financial-Times/coco-synthetic-image-publication-monitor/blob/master/helm/synthetic-image-publication-monitor/templates/deployment.yaml#L43-L44
	# kubectl describe pod $(kubectl get pods | grep synthetic-image-publication-monitor | awk '{print $1}') | grep TEST_UUID
	backend s3_eu {
		.connect_timeout = 5s;
		.dynamic = true;
		.port = "80";	
		.host = "com.ft.imagepublish.upp-prod-eu.s3.amazonaws.com";
		.host_header = "com.ft.imagepublish.upp-prod-eu.s3.amazonaws.com";
		.first_byte_timeout = 5s;
		.max_connections = 1000;
		.between_bytes_timeout = 10s;
		.probe = {
			.request = "HEAD /6a70679a-fd9b-4d64-9bec-2d340fb75021 HTTP/1.1" "Host: com.ft.imagepublish.upp-prod-eu.s3.amazonaws.com" "Connection: close" "User-Agent: Varnish/fastly (healthcheck)";
			.window = 2;
			.threshold = 1;
			.timeout = 5s;
			.initial = 1;
			.interval = 10s;
			.expected_response = 200;
		}
	}

	# k8s production EU (us-east-1) backend definition
	# 6a70679a-fd9b-4d64-9bec-2d340fb75021 - prod-us etcdctl get /ft/config/synthetic-image-publication-monitor-coco/test-uuid
	# https://github.com/Financial-Times/coco-synthetic-image-publication-monitor/blob/master/helm/synthetic-image-publication-monitor/templates/deployment.yaml#L43-L44
	# kubectl describe pod $(kubectl get pods | grep synthetic-image-publication-monitor | awk '{print $1}') | grep TEST_UUID
	backend s3_us {
		.connect_timeout = 5s;
		.dynamic = true;
		.port = "80"; 
		.host = "com.ft.imagepublish.upp-prod-us.s3.amazonaws.com";
		.host_header = "com.ft.imagepublish.upp-prod-us.s3.amazonaws.com";
		.first_byte_timeout = 5s;
		.max_connections = 1000;
		.between_bytes_timeout = 10s;
		.probe = {
			.request = "HEAD /6a70679a-fd9b-4d64-9bec-2d340fb75021 HTTP/1.1" "Host: com.ft.imagepublish.upp-prod-us.s3.amazonaws.com" "Connection: close" "User-Agent: Varnish/fastly (healthcheck)";
			.window = 2;
			.threshold = 1;
			.timeout = 5s;
			.initial = 1;
			.interval = 10s;
			.expected_response = 200;
		}

	}

sub vcl_recv {		
      if (req.restarts == 0) {
	    set req.backend = s3_eu;
	    set req.http.Host = "com.ft.imagepublish.upp-prod-eu.s3.amazonaws.com";
        set req.http.x-upp-backend="EU";
        
	    # Use US s3 bucket if the request is from the America & Asia, or EU (default) is unhealthy
	    if (client.geo.continent_code ~ "(NA|SA|OC|AS)" || !req.backend.healthy) {
		    set req.backend = s3_us;
		    set req.http.Host = "com.ft.imagepublish.upp-prod-us.s3.amazonaws.com";
		    set req.http.x-upp-backend="US";
		
		    # If both EU and US are unhealthy serve from EU
		    # Failover to EU if US backend is marked as unhealthy
		    if (!req.backend.healthy) {
			    set req.backend = s3_eu;
			    set req.http.Host = "com.ft.imagepublish.upp-prod-eu.s3.amazonaws.com";
			    set req.http.x-upp-backend="EU";
		    }
	    }
      } elsif(req.restarts == 1) { # IF the first response was 403(image missing from bucket) try the other backend if healthy regardless of location
            if (req.http.x-upp-backend == "EU") {
	    	    set req.backend = s3_us;
		        set req.http.Host = "com.ft.imagepublish.upp-prod-us.s3.amazonaws.com";
		        set req.http.x-upp-backend="US";
		        if (!req.backend.healthy) {
			        set req.backend = s3_eu;
			        set req.http.Host = "com.ft.imagepublish.upp-prod-eu.s3.amazonaws.com";
			        set req.http.x-upp-backend="EU";
       		    }
	    } elsif (req.http.x-upp-backend == "US") {
	    	set req.backend = s3_eu;
		    set req.http.Host = "com.ft.imagepublish.upp-prod-eu.s3.amazonaws.com";
		    set req.http.x-upp-backend="EU";
		    if (!req.backend.healthy) {
			    set req.backend = s3_us;
			    set req.http.Host = "com.ft.imagepublish.upp-prod-us.s3.amazonaws.com";
			    set req.http.x-upp-backend="US";
       		}
        }
     }
	
    # end default conditions
    if (req.request != "HEAD" && req.request != "GET") {
    	return(pass);
    }

    return(lookup);
}

sub vcl_fetch {
        if(beresp.status == 403 && req.restarts == 0) {
                restart;
        }
}

sub vcl_deliver {

if (req.http.x-upp-backend) {
		set resp.http.x-upp-backend = req.http.x-upp-backend;
	}

}
