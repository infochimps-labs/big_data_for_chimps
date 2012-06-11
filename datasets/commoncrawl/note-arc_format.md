# Arc File Format

From the [Internet Archive document](http://archive.org/web/researcher/ArcFileFormat.php)
Authors: Mike Burner and Brewster Kahle
Date: September 15, 1996, Version 1.0
Internet Archive

## Overview

The Archive stores the data it collects in large (currently 100MB) aggregate files for ease of storage in a conventional file system. It is the Archive's experience that it is difficult to manage hundreds of millions of small files in most existing file systems.

This document describes the format of the aggregate files. The file format was designed to meet several requirements:

* The file must be self-contained: it must permit the aggregated objects to be identified and unpacked without the use of a companion index file.
* The format must be extensible to accommodate files retrieved via a variety of network protocols, including http, ftp, news, gopher, and mail.
* The file must be "stream able": it must be possible to concatenate multiple archive files in a data stream.
* Once written, a record must be viable: the integrity of the file must not depend on subsequent creation of an in-file index of the contents.

The reader will quickly recognize, however, that an external index of the contents and object-offsets will greatly enhance the retrievability of objects stored in this format. The Archive maintains such indices, but does not seek to standardize their format.

## The Archive File Format

The description below uses pseudo-BNF to describe the archive file format. By convention, archive files are named with a ".arc" extension (e.g., "IA-000001.arc").

    arc_file         == <version_block><rest_of_arc_file> 
    version_block    == See definition below 
    rest_of_arc_file == <doc>|<doc><rest_of_arc_file> 
    doc              == <nl><URL-record><nl><network_doc> 
    URL-record       == See definition below 
    network_doc      == whatever the protocol returned 
    nl               == Unix-newline-delimiter 
    sp               == ' ' (ascii space) comma is inappropriate because it can be in an URL.


### The Version Block

The version block identifies the original filename, file version, and URL record fields of the archive file.


    version-block == filedesc://<path><sp><version specific data><sp><length><nl> 
    <version-number><sp><reserved><sp><origin-code><nl> 
    <URL-record-definition><nl> 
    <nl> 
    version-1-block == filedesc://<path><sp><ip_address><sp><date><sp>text/plain<sp><length><nl> 
    1<sp><reserved><sp><origin-code><nl> 
    <URL IP-address ArchivArchivee-date Content-type Archive-length<nl> 
    <nl> 

    version-2-block == filedesc://<path><sp><ip_address><sp><date><sp>text/plain<sp>200<sp>
    -<sp>-<sp>0<sp><filename><sp><length><nl> 

    2<sp><reserved><sp><origin-code><nl> 
    URL<sp>IP-address<sp>Archive-date<sp>Content-type<sp>Result-code<sp>Checksum<sp>Location<sp> Offset<sp>Filename<sp>Archive-length<nl> 

    <nl>

### Filedesc

The "filedesc" line is a special-case URL record (see below). The path is the original path name of the archive file. The IP address is the address of the machine that created the archive file. The date is the date the archive file was created. The content type of "text/plain" simply refers to the remainder of the version block. The length specifies the size, in bytes, of the rest of the version block.

    version-number        == integer in ascii 
    reserved              == string with no white space 
    origin-code           == Name of gathering organization with no white space 
    URL-record-definition == names of fields in URL records


### The URL Record

The URL record introduces an object in the archive file. It gives the name and size of the object, as well as several pieces of metadata about its retrieval.

    URL-record-v1 == <url><sp>
    <ip-address><sp>
    <archive-date><sp>
    <content-type><sp>
    <length><nl> 

    URL-record-v2 == <url><sp>
    <ip-address><sp>
    <archive-date><sp>
    <content-type><sp>
    <result-code><sp>
    <checksum><sp>
    <location><sp>
    <offset><sp>
    <filename><sp>
    <length><nl> 

    url          == ascii URL string (e.g., "http://www.alexa.com:80/") 
    ip_address   == dotted-quad (eg 192.216.46.98 or 0.0.0.0) 
    archive-date == date archived 
    content-type == "no-type"|MIME type of data (e.g., "text/html") 
    length       == ascii representation of size of network doc in bytes 
    date         == YYYYMMDDhhmmss (Greenwich Mean Time) 
    result-code  == result code or response code, (e.g. 200 or 302) 
    checksum     == ascii representation of a checksum of the data. The specifics of the checksum are implementation specific. 

    location     == "-"|url of re-direct 
    offset       == offset in bytes from beginning of file to beginning of URL-record 
    filename     == name of arc file 

Note that all field values are ascii text. All fields have at least one character. No field value contains a space.

## Example of an Archive File

In the following example, please remember that length includes carriage returns and line feeds.

    filedesc://IA-001102.arc 0 19960923142103 text/plain 76
    1 0 Alexa Internet
    URL IP-address Archive-date Content-type Archive-length

    http://www.dryswamp.edu:80/index.html 127.10.100.2 19961104142103 text/html 202
    HTTP/1.0 200 Document follows
    Date: Mon, 04 Nov 1996 14:21:06 GMT
    Server: NCSA/1.4.1
    Content-type: text/html Last-modified: Sat,10 Aug 1996 22:33:11 GMT
    Content-length: 30
    <HTML>
    Hello World!!!
    </HTML>

    filedesc://IA-001102.arc 0.0.0.0 19960923142103 text/plain 200 - - 0
    IA-001102.arc 122
    2 0 Alexa Internet
    URL IP-address Archive-date Content-type Result-code Checksum
    Location Offset Filename Archive-length

    http://www.dryswamp.edu:80/index.html 127.10.100.2 19961104142103
    text/html 200 fac069150613fe55599cc7fa88aa089d - 209 IA-001102.arc 202
    HTTP/1.0 200 Document follows
    Date: Mon, 04 Nov 1996 14:21:06 GMT
    Server: NCSA/1.4.1
    Content-type: text/html Last-modified: Sat,10 Aug 1996 22:33:11 GMT
    Content-length: 30
    <HTML>
    Hello World!!!
    </HTML> 

## Reading an Archive File

As noted above, the best way to retrieve a specific object from an archive file is to maintain an external database of object names, the files they are located in, their offsets within the files, and the sizes of the objects. Then, to retrieve the object, one need only open the file, seek to the offset, and do a single read of <size> bytes.

Programs that need to read the file without an index (such as to unpack the whole file) should use buffered I/O. The URL record can then be read with an fgets(), and the objects can be read with an fread() of <size> bytes.

## Using the Archive Format for other URL types

Since the Archive format uses the standard URL specification to identify objects, it naturally lends itself to the storage of data retrieved via protocols other than HTTP. For example, a news article might appear as follows:

    news:28SEP96.21024750@alligator.dryswamp.edu 127.10.100.3 19960929142103 text/plain 328
    Path: news.alexa.com!news1.best.com!news.dryswamp.edu!joebob
    From: joebob@alligator.dryswamp.edu
    Newsgroups: alt.food
    Subject: Re: I am hungry
    Date: 28 SEP 96 21:02:47 GMT
    Organization: Dry Swamp University
    Lines: 1
    Message-ID: <28SEP96.21024750@alligator.dryswamp.edu>
    NNTP-Posting-Host: alligator.dryswamp.edu
