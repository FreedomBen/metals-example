# MeTaLS-example

Link to source repository:  [https://github.com/FreedomBen/metals-example](https://github.com/FreedomBen/metals-example)

This is an example HTTP service that makes use of [MeTaLS](https://github.com/FreedomBen/metals) to add mTLS access control.  It can be used as a starting point for adding mTLS to your own service.

For more details about MeTaLS, including various configuration options, there is extensive documentation available on the [MeTaLS Github page](https://github.com/FreedomBen/metals)

This service is a fork of [echo-server](https://github.com/FreedomBen/echo-server) with a few routes that return and process JSON so you can make sure request/response bodies are making it through the proxy properly.  To see the JSON routes look in `app.rb`.  It is written in Ruby with the Sinatra library so is quite declarative and readable for anyone familiar with web services.

## Index of examples

* [Deployment using OCP Secrets](https://github.com/FreedomBen/metals-example/blob/master/examples/metals-example-ocp-secrets.yaml) for the private key and ConfigMaps for the certificates.
* [Deployment using OCP Secrets with Health Checks](https://github.com/FreedomBen/metals-example/blob/master/examples/metals-example-ocp-secrets-health-checks.yaml) both in OpenShift and externally through a Route.

## Using this service

### Starting the service locally 

Before looking into the details of MeTaLS integration, let's briefly discuss what this example service does so you know how to run/test it.  If you just want to accept it as a black box, you can skip to [running the service with MeTaLS](#running-the-service-with-metals)

For the most part the service will parse params and echo back the IP address of the caller, the HTTP verb and the path you requested, along with a Hash of the params.  This makes it easy to anticipate what a correct response should look like so you know if the proxy is working correctly.

Here are some examples of the service being called directly:

First start the app (assuming dependencies are installed. If you aren't familiar with Bundler already, I recommend just using the pre-built image below):

```bash
$ ./app.rb
```

Or you can use the pre-built image:

```bash
$ podman run --rm -it quay.io/freedomben/metals-example
```

Also available on Docker Hub:

```bash
$ podman run --rm -it [docker.io/]freedomben/metals-example
```

Or if you want to build the image locally, that's easy to do as well:

```bash
$ podman build -t metals-example .
```

### Hitting it with curl

Here are some example calls using `curl`:

```bash
[ben@host ~]$ curl localhost:8080
127.0.0.1 GET / - : {}
[ben@host ~]$ curl localhost:8080/some/path
127.0.0.1 GET /some/path - : {}
[ben@host ~]$ curl localhost:8080/some/path?with=params
127.0.0.1 GET /some/path - : {"with"=>"params"}
[ben@host ~]$ curl localhost:8080/some/path?with=params --data 'more=params&for=you'
127.0.0.1 POST /some/path - : {"with"=>"params", "more"=>"params", "for"=>"you"}
[ben@host ~]$
```

### Example calls to the JSON endpoints

```bash
[ben@host ~]$ curl localhost:8080/objects
[{"name":"objectone"},{"name":"objecttwo"}]
[ben@host ~]$ curl localhost:8080/objects/1
{"name":"objectone"}
[ben@host ~]$ curl localhost:8080/objects/ --data 'these=are&basically=ignored'
127.0.0.1 POST /objects/ - : {"these"=>"are", "basically"=>"ignored"}
```

## Running the service with MeTaLS

### Pre-requisites

1.  A way to run [OpenShift pods](https://docs.openshift.com/enterprise/3.0/architecture/core_concepts/pods_and_services.html).  I recommend using [podman](https://podman.io/) locally, or [OpenShift](https://www.openshift.com/) remotely.

### Deploying the image

If you are testing locally, you can build the image for this service locally and use it with a pod manager (like [podman](https://podman.io)).  If you want to deploy directly to an OpenShift or Kubernetes cluster, either build this image yourself and push it to your image registry, or use the pre-built one at `quay.io/freedomben/metals-example`.

If you are going to run this example on an OpenShift or Kubernetes cluster, it will have to able to pull down the image from the registry.

### ConfigMaps and Secrets for the certificates

All configuration of MeTaLS is done through environment variables.  When following the default setup, the only thing that is needed are the private key and certificates for the service.  To provide these, we will use `ConfigMaps` and `Secrets`.  This snippet is truncated for ease-of-reading.  If you want a complete and functional example, see [metals-example-ocp-secrets.yaml](https://github.com/FreedomBen/metals-example/blob/master/examples/metals-example-ocp-secrets.yaml).  Note that you will need a valid key and certificates (these can be self-generated. In the future I'll be writing a blog post about how to generate these for use in this example).

`server-key.yaml`
``` yaml
apiVersion: v1
kind: Secret
metadata:
  labels:
    app: metals-example
  name: metals-example-server-key
type: Opaque
stringData:
  METALS_PRIVATE_KEY: |
    -----BEGIN RSA PRIVATE KEY-----
    MIIJKQIBAAKCAgEAxYZUBrnPTzcnkKjg8bFtfW8lY2/xgiy9Mve0jjWEyhFPeITa
    gp5+yxdUaLJdWOMQ2qUn5LOOG20tB6L2cEXgQQEDZa0X8NbNAKI/JAhBUQUgIa/q
    PPLRAharZwpBdJ9d5rnjWpY4pODYt8gZRQKCAQAm6Wcssmi4N78Sw1YOuSSULYtW
    ...
    c9b/Y2F83Q6S0KDktekTkl1Ek+HXQujssoO2pdrNarnl7qPz3J9Ooogl81L7qYSc
    Z/O9sk5fWOkr24uVhD5hVpjJ75JR3sEaxr6Ma0aB1+RKfI5Te9YCOakvQWCMqf2h
    kc5Lsq391FjEDox1TmHBLMA9BymQg9T75y3rUD/s99XJgv1e+osHrnECSZ2l
    -----END RSA PRIVATE KEY-----
```

`client-certificates.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: metals-example-certs
data:
  METALS_PUBLIC_CERT: |
    -----BEGIN CERTIFICATE-----
    MIIJQDCCBSigAwIBAgICEAIwDQYJKoZIhvcNAQELBQAwVzELMAkGA1UEBhMCVVMx
    CzAJBgNVBAgMAklEMQ4wDAYDVQQHDAVCb2lzZTEXMBUGA1UECgwOQm9pc2UgQmFu
    ayBMVEQxEjAQBgNVBAMMCWxvY2FsaG9zdDAeFw0yMDAzMTMwMzExMzNaFw0yMjAz
    ...
    595sGnGOAyRcJ0BL6xcEHGBpUDqgpoYhILOsQ1umsbFBCyjtigu9Vj9fKEXD2Ml7
    4jx4azZl6/kWGclOL9eqbbQXtFOR3BRAvGh2vvKNSIytpdRvES7fCWnKDYOjoR4B
    JwE95codjcYbBmseuBJUc03wwtk=
    -----END CERTIFICATE-----
  METALS_SERVER_TRUST_CHAIN: |
    -----BEGIN CERTIFICATE-----
    MIIJgTCCBWmgAwIBAgIJAI45yy3ikizxMA0GCSqGSIb3DQEBCwUAMFcxCzAJBgNV
    BAYTAlVTMQswCQYDVQQIDAJJRDEOMAwGA1UEBwwFQm9pc2UxFzAVBgNVBAoMDkJv
    aXNlIEJhbmsgTFREMRIwEAYDVQQDDAlsb2NhbGhvc3QwHhcNMjAwMzEzMDI0OTE2
    ...
    ZBzA4jTxO0Ov3hNivLahf/Bx4+Ek7y5x/zgcxWCsAgowpWXN4pIv3aEPn9unDJJz
    xnFvoY0R3gx/AvDM0+MHUMgbDBSVXBx8vK9JhYIFI+0E301bRgo3IGKzZeLTdTT1
    XuV865TpREo5JquzQWxJtbyKxjJa5RY7f9kN5lRFpzteY560YA==
    -----END CERTIFICATE-----
```

For more information about what these variables do, [take a look at the comments in the example file](https://github.com/FreedomBen/metals-example/blob/master/examples/metals-example-ocp-secrets-health-checks.yaml), or consult [the documentation for the variables in the project](https://github.com/FreedomBen/metals#variables).

Apply the files to your cluster:

```bash
$ oc apply -f server-key.yaml
$ oc apply -f client-certificates.yaml
```

### Create a Deployment

Now that we have our configuration data in place, we need to get some running pods.  Rather than run them directly, we will use a Deployment to manage them.  This was we can easily spin up additional replicas as we need to scale, and it the application crashes it will automatically be restarted for us but the supervisor.

`metals-example-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: metals-example
  name: metals-example
spec:
  replicas: 1
  selector:
    matchLabels:
      app: metals-example
  template:
    metadata:
      labels:
        app: metals-example
    spec:
      containers:
      - image: quay.io/freedomben/metals-example:latest
        name: metals-example
        imagePullPolicy: Always
        env:
        - name: APP_ROOT
          value: /opt/app-root
        - name: HOME
          value: /opt/app-root/src
      - image: quay.io/freedomben/metals:latest
        name: metals
        imagePullPolicy: Always
        ports:
        - containerPort: 8443
          protocol: TCP
        envFrom:
        - configMapRef:
            name: metals-example-certs
        - secretRef:
            name: metals-example-server-key
```

Apply the file to your cluster:

```bash
$ oc apply -f metals-example-deployment.yaml
```

### Expose the app with a Service

In order for our Deployment to be easily accessible, we need to create a Service for it:

`metals-example-service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: metals-example
  name: metals-example
spec:
  ports:
  - name: 8443-tcp
    port: 8443
    protocol: TCP
    targetPort: 8443
  selector:
    deployment: metals-example
```

Apply the file to your cluster:

```bash
$ oc apply -f metals-example-service.yaml
```

### Expose the Service outside the cluster with a Route

For hitting the echo server from outside the cluster, we will expose it with a Route:

`metals-example-route.yaml`
```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
    app: metals-example
  name: metals-example
spec:
  port:
    targetPort: 8443-tcp
  to:
    kind: Service
    name: metals-example
    weight: 100
  wildcardPolicy: None
  tls:
    termination: passthrough
```

Apply the file to your cluster:

```bash
$ oc apply -f metals-example-route.yaml
```

### Test the application

Now that the application is exposed with a Route, we can curl it from our local machine!  Remember tho that we need a valid client certificate in order to get through the MeTaLS proxy.  Your endpoints will be different, and you will need the client certificates and the trust chain locally for providing to curl.  These examples should be adjusted appropriately.

Results should be the same as above when we were testing the app locally when our certificate is valid:

```bash
$ export TARGET_HOST=localhost:8443
$ curl \
    --cacert ./rootca.pem \
    --key ./client.key \
    --cert ./client.crt \
    https://$TARGET_HOST/testing/mtls/long/path?querystring=thisvalue
```

Reponse:

```bash
10.88.0.1 GET /testing/mtls/long/path - : {"querystring"=>"thisvalue"}
```

With a missing certificate, we get a 400 back and the request is never proxied to the echo server:

```bash
$ curl \
    --cacert ./rootca.pem \
    https://${TARGET_HOST}/testing/mtls/long/path?querystring=thisvalue
```

Response:

```bash
<html>
<head><title>400 No required SSL certificate was sent</title></head>
<body bgcolor="white">
<center><h1>400 Bad Request</h1></center>
<center>No required SSL certificate was sent</center>
<hr><center>nginx/1.14.1</center>
</body>
</html>
```

With an invalid certificate, we likewise receive a 400 (with slightly different HTML) and the request is never proxied to the echo server.

```bash
$ curl \
    --cacert ./rootca.pem \
    --key ./valid-but-untrusted-client.key \
    --cert ./valid-but-untrusted-client.crt \
    https://${TARGET_HOST}/testing/mtls/long/path?querystring=thisvalue
```

Response:

```bash
<html>
<head><title>400 The SSL certificate error</title></head>
<body bgcolor="white">
<center><h1>400 Bad Request</h1></center>
<center>The SSL certificate error</center>
<hr><center>nginx/1.14.1</center>
</body>
</html>
```

### What's next?

Now that you've seen an example, get some certificates and try adding it to one of your own service!

