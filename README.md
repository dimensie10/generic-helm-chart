#

## Configuring ConfigMaps

### Structure
```
configmaps:
  <configmap-name+>:
    <target-path+>:
      <target-filename+>:
        [nochecksum: <true|false>]
        contents: |-
          contents-of-your-config-file
```

Using the `.Values.configmaps` map, it's possible to create one or more ConfigMaps. Each ConfigMap can contain one or more paths, and each path can contain one or more files. Each ConfigMaps' name is a concatenation of the charts' fullname and the configured name of the configmap, separated by dash.

For each file contained in a ConfigMap, a configchecksum will be generated by default in the pod annotations. It is possible to disable this behaviour on global level, on ConfigMap level, on path level and on file level by setting the key `nochecksum` to `true`. The contents of the file needs to be defined on file level under the key `contents`.

If you use helmfile, and you name your values file with extension `.gotmpl`, you can use the helm template function `readFile` inside the values file to load the contents from an external file.

### Example

#### Definition

```
configmaps:
  myconfigmap:
    "/etc/generic-helm-chart":
      "config.txt":
        nochecksum: true
        contents: |-
          This is my config
      "config2.txt":
        contents: |-
          This is my config2
    "/etc/generic-helm-chart2":
      nochecksum: true
      "alsoconfig.txt":
        contents: |-
          This is also my config
      "alsoconfig2.txt":
        contents: |-
          This is also my config2
  myconfigmap2:
    "/etc/generic-helm-chart3":
      "3config.txt":
        contents: |-
          3This is my config
      "3config2.txt":
        contents: |-
          3This is my config2
    "/etc/generic-helm-chart4":
      "4alsoconfig.txt":
        contents: |-
          4This is also my config
      "4alsoconfig2.txt":
        contents: |-
          4This is also my config2
  myconfigmap3:
    nochecksum: true
    "/etc/generic-helm-chart5":
      "5config.txt":
        contents: |-
          5This is my config
      "5config2.txt":
        contents: |-
          5This is my config2
    "/etc/generic-helm-chart6":
      "6alsoconfig.txt":
        contents: |-
          6This is also my config
      "6alsoconfig2.txt":
        contents: |-
          {{ readFile "6alsoconfig2.txt" | indent 10 }}
```

#### Helmfile diff output of example

```
Comparing release=generic-helm-chart, chart=generic-helm-chart/generic-helm-chart
generic-helm-chart-test, generic-helm-chart, Deployment (apps) has changed:
  # Source: generic-helm-chart/templates/deployment.yaml
  ...
  spec:
    ...
    template:
      metadata:
+       annotations:
+         configchecksum:
+           myconfigmap:/etc/generic-helm-chart/config2.txt=c5e5d1c2f5faa2e4c8456e6bff64aeafd967366887f6acd728038c6b870a9c3
+           myconfigmap2:/etc/generic-helm-chart3/3config.txt=e75bae93c0ee37bc2582c9063c6c7d9a719897066786b817d6a0bf59a61f75e
+           myconfigmap2:/etc/generic-helm-chart3/3config2.txt=cec2d2edcfaf82a85b095373462990cf4d68e3197a117ddf8da23e21c2e8c80
+           myconfigmap2:/etc/generic-helm-chart4/4alsoconfig.txt=1ab812b30d00880c849d03bcc367355ceaa85570288e740785d5fcc87732f01
+           myconfigmap2:/etc/generic-helm-chart4/4alsoconfig2.txt=344a47064869f865e09e36f65b452b1bc116da6e335dde87322f6e7deace115
...
+           volumeMounts:
+             - name: myconfigmap
+               mountPath: /etc/generic-helm-chart/config.txt
+               subPath: /etc/generic-helm-chart/config.txt
+             - name: myconfigmap
+               mountPath: /etc/generic-helm-chart/config2.txt
+               subPath: /etc/generic-helm-chart/config2.txt
+             - name: myconfigmap
+               mountPath: /etc/generic-helm-chart2/alsoconfig.txt
+               subPath: /etc/generic-helm-chart2/alsoconfig.txt
+             - name: myconfigmap
+               mountPath: /etc/generic-helm-chart2/alsoconfig2.txt
+               subPath: /etc/generic-helm-chart2/alsoconfig2.txt
+             - name: myconfigmap2
+               mountPath: /etc/generic-helm-chart3/3config.txt
+               subPath: /etc/generic-helm-chart3/3config.txt
+             - name: myconfigmap2
+               mountPath: /etc/generic-helm-chart3/3config2.txt
+               subPath: /etc/generic-helm-chart3/3config2.txt
+             - name: myconfigmap2
+               mountPath: /etc/generic-helm-chart4/4alsoconfig.txt
+               subPath: /etc/generic-helm-chart4/4alsoconfig.txt
+             - name: myconfigmap2
+               mountPath: /etc/generic-helm-chart4/4alsoconfig2.txt
+               subPath: /etc/generic-helm-chart4/4alsoconfig2.txt
+             - name: myconfigmap3
+               mountPath: /etc/generic-helm-chart5/5config.txt
+               subPath: /etc/generic-helm-chart5/5config.txt
+             - name: myconfigmap3
+               mountPath: /etc/generic-helm-chart5/5config2.txt
+               subPath: /etc/generic-helm-chart5/5config2.txt
+             - name: myconfigmap3
+               mountPath: /etc/generic-helm-chart6/6alsoconfig.txt
+               subPath: /etc/generic-helm-chart6/6alsoconfig.txt
+             - name: myconfigmap3
+               mountPath: /etc/generic-helm-chart6/6alsoconfig2.txt
+               subPath: /etc/generic-helm-chart6/6alsoconfig2.txt
...
+       volumes:
+         - name: myconfigmap
+           configMap:
+             name: rechtsorde-denhollander-bridge-myconfigmap
+         - name: myconfigmap2
+           configMap:
+             name: rechtsorde-denhollander-bridge-myconfigmap2
+         - name: myconfigmap3
+           configMap:
+             name: rechtsorde-denhollander-bridge-myconfigmap3
...
generic-helm-chart-test, generic-helm-chart, ConfigMap (v1) has been added:
+ # Source: generic-helm-chart/templates/configmap.yaml
+ apiVersion: v1
+ kind: ConfigMap
+ metadata:
+   name: generic-helm-chart-myconfigmap
+ data:
+   config.txt: |-
+     This is my config
+   config2.txt: |-
+     This is my config2
+   alsoconfig.txt: |-
+     This is also my config
+   alsoconfig2.txt: |-
+     This is also my config2
...
generic-helm-chart-test, generic-helm-chart, ConfigMap (v1) has been added:
+ # Source: generic-helm-chart/templates/configmap.yaml
+ apiVersion: v1
+ kind: ConfigMap
+ metadata:
+   name: generic-helm-chart-myconfigmap2
+ data:
+   3config.txt: |-
+     3This is my config
+   3config2.txt: |-
+     3This is my config2
+   4alsoconfig.txt: |-
+     4This is also my config
+   4alsoconfig2.txt: |-
+     4This is also my config2
...
generic-helm-chart-test, generic-helm-chart, ConfigMap (v1) has been added:
+ # Source: generic-helm-chart/templates/configmap.yaml
+ apiVersion: v1
+ kind: ConfigMap
+ metadata:
+   name: generic-helm-chart-myconfigmap3
+ data:
+   5config.txt: |-
+     5This is my config
+   5config2.txt: |-
+     5This is my config2
+   6alsoconfig.txt: |-
+     6This is also my config
+   6alsoconfig2.txt: |-
+     6This is also my config2
```