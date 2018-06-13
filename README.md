# json_transcript_transformer
Tool for transforming JSON-formatted time-stamped transcripts created by Kaldi into transcripts with 5-7 second phrases

This was built for the [American Archive of Public Broadcasting](http://americanarchive.org)'s use case. The AAPB uses a [version of the Kaldi speech to text tool](https://github.com/hipstas/kaldi-pop-up-archive) to generate transcripts for audio and video files. The Kaldi output is .txt and .json files that have timestamps for each word. In the AAPB's use case, the transcripts need to be broken up into 5-7 second phrases, with start and end times for each phrase. This script transforms the Kaldi output into the AAPB's preferred format. 

This is a script that uses jq and BASH standard utilities basename, cat, cut, dirname, echo, grep, head, printf, pwd, sed, tr
Required: jq: https://github.com/stedolan/jq


The script expects that the input file is valid JSON, has a parent directory with a meaningful name, and the only meaningful part of the filename is prior to the first .
