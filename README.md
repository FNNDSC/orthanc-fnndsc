# orthanc-fnndsc
An dockerized instance of Orthanc, with some FNNDSC-specific components.


### Development

In this directory, find the `orthanc.json` file and make the following edits

- Find the `"DicomModalities"` block in the JSON file, and find the `"CHRISLOCAL"` key.

  ```json
  // ...
  "DicomModalities": {
  	// ...
  	"CHRISLOCAL" : ["CHRISLOCAL", "192.168.1.189", 11113 ],
  }
  ```

- Edit the IP address in this key (192.168.1.189 in this example), to your local machine's IP address. You can either find this by using the `ip` command or set this to 127.0.0.1 (loopback IP).

- Now run orthanc with

  ```bash
  ./make.sh -i
  ```

To make sure Orthanc started successfully, open `http://localhost:8042` in a browser and you should get a Basic Auth prompt. Use username `orthanc` and password `orthanc` which are the defaults. You should now be able to interact with Orthanc and upload files.
