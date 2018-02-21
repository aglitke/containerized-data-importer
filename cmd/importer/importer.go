package main

import (
	"flag"
	"net/url"

	"github.com/golang/glog"
	. "github.com/kubevirt/containerized-data-importer/pkg/importer"
)

// importer.go implements a data fetching service capable of pulling objects from remote object stores
// and writing to a local directory.  It utilizes the minio-go client sdk.
// This process expects several environmental variables:
//    IMPORTER_URL            Full url + path to object. Mutually exclusive with IMPORTER_ENDPOINT
//    IMPORTER_ENDPOINT       Endpoint url minus scheme, bucket/object and port, eg. s3.amazon.com
//			      			    Mutually exclusive with IMPORTER_URL
//    IMPORTER_OBJECT_PATH    Full path of object (e.g. bucket/object)
//    access and secret keys are optional. If omitted no creds are passed to the object store client
//    IMPORTER_ACCESS_KEY_ID  Optional. Access key is the user ID that uniquely identifies your account.
//    IMPORTER_SECRET_KEY     Optional. Secret key is the password to your account


const (
	WRITE_PATH             = "/disk.img"
	IMPORTER_ENDPOINT      = "IMPORTER_ENDPOINT"
	IMPORTER_ACCESS_KEY_ID = "IMPORTER_ACCESS_KEY_ID"
	IMPORTER_SECRET_KEY    = "IMPORTER_SECRET_KEY"
)

func init() {
	flag.Parse()
}

func main() {
	defer glog.Flush()
	glog.Infoln("Starting importer")
	ep := ParseEnvVar(IMPORTER_ENDPOINT, false)
	acc := ParseEnvVar(IMPORTER_ACCESS_KEY_ID, false)
	sec := ParseEnvVar(IMPORTER_SECRET_KEY, false)
	importInfo, err := NewImportInfo(ep, acc, sec)
	if err != nil {
		glog.Fatalf("main(): unable to get env variables: %v\n", err)
	}
	importInfo.Url, err = url.Parse(importInfo.Endpoint)
	if err != nil {
		glog.Fatalf("main(): \n")
	}
	dataReader, filename, err := NewDataReader(importInfo)
	defer dataReader.Close()
	if err != nil {
		glog.Fatalf("main(): unable to create data reader: %v\n", err)
	}
	glog.Infof("Beginning import of %s\n", filename)
	if err = StreamDataToFile(dataReader, WRITE_PATH); err != nil {
		glog.Fatalf("main: unable to stream data to file: %v\n", err)
	}
	glog.Infoln("Import complete, exiting")
}


