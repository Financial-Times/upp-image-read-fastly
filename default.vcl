	# EU (eu-west-1) backend definition
	# c94a3a57-3c99-423c-a6bd-ed8c4c10a3c3 - prod-uk etcdctl get /ft/config/synthetic-image-publication-monitor-coco/test-uuid 
	backend s3_eu {
		.connect_timeout = 5s;
		.dynamic = true;
		.port = "80";	
		.host = "com.ft.imagepublish.prod.s3.amazonaws.com";
		.host_header = "com.ft.imagepublish.prod.s3.amazonaws.com";
		.first_byte_timeout = 5s;
		.max_connections = 1000;
		.between_bytes_timeout = 10s;
		.probe = {
			.request = "HEAD /c94a3a57-3c99-423c-a6bd-ed8c4c10a3c3 HTTP/1.1" "Host: com.ft.imagepublish.prod.s3.amazonaws.com" "Connection: close" "User-Agent: Varnish/fastly (healthcheck)";
			.window = 2;
			.threshold = 1;
			.timeout = 5s;
			.initial = 1;
			.interval = 10s;
			.expected_response = 200;
		}
	}

	# US (us-east-1) backend definition
	# 43eabb23-88a2-4e62-a4dc-6e1e8f737c1f - prod-us etcdctl get /ft/config/synthetic-image-publication-monitor-coco/test-uuid 
	backend s3_us {
		.connect_timeout = 5s;
		.dynamic = true;
		.port = "80"; 
		.host = "com.ft.imagepublish.prod-us.s3.amazonaws.com";
		.host_header = "com.ft.imagepublish.prod-us.s3.amazonaws.com";
		.first_byte_timeout = 5s;
		.max_connections = 1000;
		.between_bytes_timeout = 10s;
		.probe = {
			.request = "HEAD /43eabb23-88a2-4e62-a4dc-6e1e8f737c1f HTTP/1.1" "Host: com.ft.imagepublish.prod-us.s3.amazonaws.com" "Connection: close" "User-Agent: Varnish/fastly (healthcheck)";
			.window = 2;
			.threshold = 1;
			.timeout = 5s;
			.initial = 1;
			.interval = 10s;
			.expected_response = 200;
		}

	}


sub vcl_recv {

	set req.backend = s3_eu;
	set req.http.Host = "com.ft.imagepublish.prod.s3.amazonaws.com";

	# Use US s3 bucket if the request is from the America & Asia, or EU (default) is unhealthy
	if (geoip.continent_code ~ "(NA|SA|OC|AS)" || !req.backend.healthy) {

		set req.backend = s3_us;
		set req.http.Host = "com.ft.imagepublish.prod-us.s3.amazonaws.com";

		# Failover to EU if US backend is marked as unhealthy
		if (!req.backend.healthy) {
			set req.backend = s3_eu;
			set req.http.Host = "com.ft.imagepublish.prod.s3.amazonaws.com";
		}
	}

    # end default conditions
    if (req.request != "HEAD" && req.request != "GET") {
    	return(pass);
    }

    return(lookup);
}
