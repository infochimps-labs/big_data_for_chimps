## Fields

From the [original documentation](http://labrosa.ee.columbia.edu/millionsong/pages/field-list):

Field name                 	Type          	Description                                  	Link
analysis sample rate       	float         	sample rate of the audio used                	url 
artist 7digitalid          	int           	ID from 7digital.com or -1                   	url 
artist familiarity         	float         	algorithmic estimation                       	url 
artist hotttnesss          	float         	algorithmic estimation                       	url 
artist id                  	string        	Echo Nest ID                                 	url 
artist latitude            	float         	latitude                                     
artist location            	string        	location name                                
artist longitude           	float         	longitude                                    
artist mbid                	string        	ID from musicbrainz.org                      	url 
artist mbtags              	array string  	tags from musicbrainz.org                    	url 
artist mbtags count        	array int     	tag counts for musicbrainz tags              	url 
artist name                	string        	artist name                                  	url 
artist playmeid            	int           	ID from playme.com, or -1                    	url 
artist terms               	array string  	Echo Nest tags                               	url 
artist terms freq          	array float   	Echo Nest tags freqs                         	url 
artist terms weight        	array float   	Echo Nest tags weight                        	url 
audio md5                  	string        	audio hash code                              
bars confidence            	array float   	confidence measure                           	url 
bars start                 	array float   	beginning of bars, usually on a beat         	url 
beats confidence           	array float   	confidence measure                           	url 
beats start                	array float   	result of beat tracking                      	url 
danceability               	float         	algorithmic estimation                       
duration                   	float         	in seconds                                   
end of fade in             	float         	seconds at the beginning of the song         	url 
energy                     	float         	energy from listener point of view           
key                        	int           	key the song is in                           	url 
key confidence             	float         	confidence measure                           	url 
loudness                   	float         	overall loudness in dB                       	url 
mode                       	int           	major or minor                               	url 
mode confidence            	float         	confidence measure                           	url 
release                    	string        	album name                                   
release 7digitalid         	int           	ID from 7digital.com or -1                   	url 
sections confidence        	array float   	confidence measure                           	url 
sections start             	array float   	largest grouping in a song, e.g. verse       	url 
segments confidence        	array float   	confidence measure                           	url 
segments loudness max      	array float   	max dB value                                 	url 
segments loudness max time 	array float   	time of max dB value, i.e. end of attack     	url 
segments loudness max start	array float   	dB value at onset                            	url 
segments pitches           	2D array float	chroma feature, one value per note           	url 
segments start             	array float   	musical events, ~ note onsets                	url 
segments timbre            	2D array float	texture features (MFCC+PCA-like)             	url 
similar artists            	array string  	Echo Nest artist IDs (sim. algo. unpublished)	url 
song hotttnesss            	float         	algorithmic estimation                       
song id                    	string        	Echo Nest song ID                            
start of fade out          	float         	time in sec                                  	url 
tatums confidence          	array float   	confidence measure                           	url 
tatums start               	array float   	smallest rythmic element                     	url 
tempo                      	float         	estimated tempo in BPM                       	url 
time signature             	int           	estimate of number of beats per bar, e.g. 4  	url 
time signature confidence  	float         	confidence measure                           	url 
title                      	string        	song title                                   
track id                   	string        	Echo Nest track ID                           
track 7digitalid           	int           	ID from 7digital.com or -1                   	url 
year                       	int           	song release year from MusicBrainz or 0      	url 


An [Example Track Description](http://labrosa.ee.columbia.edu/millionsong/pages/example-track-description)

Below is a list of all the fields associated with each track in the database. This is simply an annotated version of the output of the example code display_song.py. For the fields that include a large amount of numerical data, we indicate only the shape of the data array. Since most of these fields are taken directly from the Echo Nest Analyze API, more details can be found at the Echo Nest Analyze API documentation.

A more technically-oriented list of these fields is given on the field list page.

This example data is shown for the track whose track_id is TRAXLZU12903D05F94 - namely, "Never Gonna Give You Up" by Rick Astley.

artist_mbid:               	db92a151-1ac2-438b-bc43-b82e149ddd50		the musicbrainz.org ID for this artists is db9...                                                   
artist_mbtags:             	shape = (4,)                        		this artist received 4 tags on musicbrainz.org                                                      
artist_mbtags_count:       	shape = (4,)                        		raw tag count of the 4 tags this artist received on musicbrainz.org                                 
artist_name:               	Rick Astley                         		artist name                                                                                         
artist_playmeid:           	1338                                		the ID of that artist on the service playme.com                                                     
artist_terms:              	shape = (12,)                       		this artist has 12 terms (tags) from The Echo Nest                                                  
artist_terms_freq:         	shape = (12,)                       		frequency of the 12 terms from The Echo Nest (number between 0 and 1)                               
artist_terms_weight:       	shape = (12,)                       		weight of the 12 terms from The Echo Nest (number between 0 and 1)                                  
audio_md5:                 	bf53f8113508a466cd2d3fda18b06368    		hash code of the audio used for the analysis by The Echo Nest                                       
bars_confidence:           	shape = (99,)                       		confidence value (between 0 and 1) associated with each bar by The Echo Nest                        
bars_start:                	shape = (99,)                       		start time of each bar according to The Echo Nest, this song has 99 bars                            
beats_confidence:          	shape = (397,)                      		confidence value (between 0 and 1) associated with each beat by The Echo Nest                       
beats_start:               	shape = (397,)                      		start time of each beat according to The Echo Nest, this song has 397 beats                         
danceability:              	0.0                                 		danceability measure of this song according to The Echo Nest (between 0 and 1, 0 => not analyzed)   
duration:                  	211.69587                           		duration of the track in seconds                                                                    
end_of_fade_in:            	0.139                               		time of the end of the fade in, at the beginning of the song, according to The Echo Nest            
energy:                    	0.0                                 		energy measure (not in the signal processing sense) according to The Echo Nest (between 0 and 1, 0 => not analyzed)
key:                       	1                                   		estimation of the key the song is in by The Echo Nest                                               
key_confidence:            	0.324                               		confidence of the key estimation                                                                    
loudness:                  	-7.75                               		general loudness of the track                                                                       
mode:                      	1                                   		estimation of the mode the song is in by The Echo Nest                                              
mode_confidence:           	0.434                               		confidence of the mode estimation                                                                   
release:                   	Big Tunes - Back 2 The 80s          		album name from which the track was taken, some songs / tracks can come from many albums, we give only one
release_7digitalid:        	786795                              		the ID of the release (album) on the service 7digital.com                                           
sections_confidence:       	shape = (10,)                       		confidence value (between 0 and 1) associated with each section by The Echo Nest                    
sections_start:            	shape = (10,)                       		start time of each section according to The Echo Nest, this song has 10 sections                    
segments_confidence:       	shape = (935,)                      		confidence value (between 0 and 1) associated with each segment by The Echo Nest                    
segments_loudness_max:     	shape = (935,)                      		max loudness during each segment                                                                    
segments_loudness_max_time:	shape = (935,)                      		time of the max loudness during each segment                                                        
segments_loudness_start:   	shape = (935,)                      		loudness at the beginning of each segment                                                           
segments_pitches:          	shape = (935, 12)                   		chroma features for each segment (normalized so max is 1.)                                          
segments_start:            	shape = (935,)                      		start time of each segment (~ musical event, or onset) according to The Echo Nest, this song has 935 segments
segments_timbre:           	shape = (935, 12)                   		MFCC-like features for each segment                                                                 
similar_artists:           	shape = (100,)                      		a list of 100 artists (their Echo Nest ID) similar to Rick Astley according to The Echo Nest        
song_hotttnesss:           	0.864248830588                      		according to The Echo Nest, when downloaded (in December 2010), this song had a 'hotttnesss' of 0.8 (on a scale of 0 and 1)
song_id:                   	SOCWJDB12A58A776AF                  		The Echo Nest song ID, note that a song can be associated with many tracks (with very slight audio differences)
start_of_fade_out:         	198.536                             		start time of the fade out, in seconds, at the end of the song, according to The Echo Nest          
tatums_confidence:         	shape = (794,)                      		confidence value (between 0 and 1) associated with each tatum by The Echo Nest                      
tatums_start:              	shape = (794,)                      		start time of each tatum according to The Echo Nest, this song has 794 tatums                       
tempo:                     	113.359                             		tempo in BPM according to The Echo Nest                                                             
time_signature:            	4                                   		time signature of the song according to The Echo Nest, i.e. usual number of beats per bar           
time_signature_confidence: 	0.634                               		confidence of the time signature estimation                                                         
title:                     	Never Gonna Give You Up             		song title                                                                                          
track_7digitalid:          	8707738                             		the ID of this song on the service 7digital.com                                                     
track_id:                  	TRAXLZU12903D05F94                  		The Echo Nest ID of this particular track on which the analysis was done                            
year:                      	1987                                		year when this song was released, according to musicbrainz.org                                      
