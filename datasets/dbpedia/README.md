# DBpedia Datasets

The DBpedia project extracts various kinds of structured information from Wikipedia editions in 97 languages and combines this information into a huge, cross-domain knowledge base. [^fn1]

The DBpedia knowledge base currently describes more than

* 3.64 million total things -- see, for example, the [DBpedia entry for "Chimpanzee"](http://dbpedia.org/page/Chimpanzee)
* 1.83 million of those things are classified in a consistent Ontology, including
  - 416,000 persons,
  - 526,000 places (including 360,000 populated places),
  - 106,000 music albums,
  -  60,000 films,
  -  17,500 video games,
  - 169,000 organizations (including 40,000 companies and 38,000 educational institutions),
  - 183,000 species and 5,400 diseases.
* Labels and abstracts for these 3.64 million things in up to 97 different languages
* 2,724,000 links to images
* 6,300,000 links to external web pages
* 6,200,000 external links into other RDF datasets
* 740,000 Wikipedia categories
* 2,900,000 YAGO categories.

The dataset consists of 1 billion pieces of information (RDF triples) out of which 385 million were extracted from the English edition of Wikipedia and roughly 665 million were extracted from other language editions and links to external datasets. *note: only the english language versions are used in the infochimps collection.*

[^fn1] This documentation extracted from [DBpedia web site](http://wiki.dbpedia.org/Datasets)

## Datasets Used

[DBpedia Core Datasets](http://wiki.dbpedia.org/Datasets), version [3.7](http://wiki.dbpedia.org/Downloads37):

Content:

* [Titles](http://downloads.dbpedia.org/3.7/en/labels_en.nq.bz2) -- Titles of all Wikipedia Articles in the corresponding language
* [Extended Abstracts](http://downloads.dbpedia.org/3.7/en/long_abstracts_en.nq.bz2) -- Additional, extended English abstracts of Wikipedia Articles
* [Page IDs](http://downloads.dbpedia.org/3.7/en/page_ids_en.nq.bz2) -- Wikipedia's Numeric Page IDs
* [Revision IDs](http://downloads.dbpedia.org/3.7/en/revisions_en.nq.bz2) -- Wikipedia Revision IDs as of this DBpedia version

Extracted Properties:

These are hand-generated mappings of Wikipedia infoboxes/templates to the DBpedia ontology. The mappings adjust weaknesses in the Wikipedia infobox system, like using different infoboxes for the same type of thing (class) or using different property names for the same property. Therefore, the instance data within the infobox ontology is much cleaner and better structured than the Infobox Dataset, but currently doesn't cover all infobox types and infobox properties within Wikipedia. There are three different Infobox Ontology data sets:

* [Ontology Infobox Types](http://downloads.dbpedia.org/3.7/en/instance_types_en.nq.bz2) -- the rdf:types of of the instances which have been extracted from the infoboxes.
* [Ontology Infobox Properties (Strict)](http://downloads.dbpedia.org/3.7/en/mappingbased_properties_en.nq.bz2) -- The actual data values that have been extracted from infoboxes. The data values are represented using ontology properties (e.g., 'volume') that may be applied to different things (e.g., the volume of a lake and the volume of a planet). This restricts the number of different properties to a minimum, but has the drawback that it is not possible to automatically infer the class of an entity based on a property. For instance, an application that discovers an entity described using the volume property cannot infer that that the entity is a lake and then for example use a map to visualize the entity. Properties are represented using properties following the `http://dbpedia.org/ontology/{propertyname}` naming schema. All values are normalized to their respective SI unit.
* [Ontology Infobox Properties (Loose)](http://downloads.dbpedia.org/3.7/en/specific_mappingbased_properties_en.nq.bz2) -- Properties which have been specialized for a specific class using a specific unit. e.g. the property height is specialized on the class Person using the unit centimetres instead of metres. Specialized properties follow the `http://dbpedia.org/ontology/{Class}/{property}` naming schema (e.g. `http://dbpedia.org/ontology/Person/height`). The properties have a single class as rdfs:domain and rdfs:range and can therefore be used for classification reasoning. This makes it easier to express queries against the data, e.g., finding all lakes whose volume is in a certain range. Typically, the range of the properties are not using SI units, but a unit which is more appropriate in the specific domain.

Categories:

* [Articles Categories](http://downloads.dbpedia.org/3.7/en/article_categories_en.nq.bz2) -- Links from concepts to categories using the SKOS vocabulary.
* [Categories (Labels)](http://downloads.dbpedia.org/3.7/en/category_labels_en.nq.bz2) -- Labels for Categories
* [Categories (Skos)](http://downloads.dbpedia.org/3.7/en/skos_categories_en.nq.bz2) -- Information which concept is a category and how categories are related using the SKOS Vocabulary.
* [YAGO]() -- derived from the Wikipedia category system using Word Net. Please refer to Yago: A Core of Semantic Knowledge – Unifying WordNet and Wikipedia for more details.

Hyperlinks:

*(to avoid confusion, we'll specifically use 'hyperlink' to refer to links from wikipedia pages to other pages inside or outside wikipedia).

* [External Hyperlinks](http://downloads.dbpedia.org/3.7/en/external_links_en.nq.bz2) -- Hyperlinks to external web pages about a concept.
* [Links to Wikipedia Article](http://downloads.dbpedia.org/3.7/en/wikipedia_links_en.nq.bz2) -- Links to corresponding Articles in Wikipedia
* [Wikipedia Pagelinks](http://downloads.dbpedia.org/3.7/en/page_links_en.nq.bz2) -- internal links between DBpedia instances. The dataset was created from the internal pagelinks between Wikipedia articles.
* [Redirects](http://downloads.dbpedia.org/3.7/en/redirects_en.nq.bz2) -- redirects between Articles in Wikipedia, used when one topic might be known under several distinct names.
* [Disambiguation Links](http://downloads.dbpedia.org/3.7/en/disambiguations_en.nq.bz2) -- used when distinct, unrelated topics might be know by the same page name.
* [Images](http://downloads.dbpedia.org/3.7/en/images_en.nq.bz2) -- Thumbnail Links from Wikipedia Articles

Entity Metadata:

* [Geographic Coordinates](http://downloads.dbpedia.org/3.7/en/geo_coordinates_en.nq.bz2) -- geo-coordinates for 697,000 geographic locations. Geo-coordinates are expressed using the [W3C Basic Geo Vocabulary](http://www.w3.org/2003/01/geo/).
* [Homepages](http://downloads.dbpedia.org/3.7/en/homepages_en.nq.bz2) -- Links to external webpages nominated as the 'homepage' of an entity.
* [Persondata](http://downloads.dbpedia.org/3.7/en/persondata_en.nq.bz2) -- Information about persons (date, place of birth, etc.).
* [PND](http://downloads.dbpedia.org/3.7/en/pnd_en.nq.bz2) -- Personennamendatei identifiers, a uniform identifier set for notable people.
* [DBpedia External references: Eurostat](http://downloads.dbpedia.org/3.7/links/eurostat_links.nt.bz2) -- Links between countries and regions in DBpedia and data about them from Eurostat. Links were created manually.
* [DBpedia External references: CIA Factbook](http://downloads.dbpedia.org/3.7/links/factbook_links.nt.bz2) -- Links between countries in DBpedia and data about them from CIA Factbook. Links were created manually.
* [DBpedia External references: flickr wrappr](http://downloads.dbpedia.org/3.7/links/flickrwrapper_links.nt.bz2) -- Links between DBpedia concepts and photo collections depicting them generated by the flikr wrappr. 
* [DBpedia External references: Freebase](http://downloads.dbpedia.org/3.7/links/freebase_links.nt.bz2) -- Links between DBpedia and Freebase (MIDs).
* [DBpedia External references: Geonames](http://downloads.dbpedia.org/3.7/links/geonames_links.nt.bz2) -- Links between geographic places in DBpedia and data about them in the Geonames database. Provided by the Geonames people. 
* [DBpedia External references: MusicBrainz](http://downloads.dbpedia.org/3.7/links/musicbrainz_links.nt.bz2) -- Links between artists, albums and songs in DBpedia and data about them from MusicBrainz. Created manually using the result of SPARQL queries. 
* [DBpedia External references: New York Times](http://downloads.dbpedia.org/3.7/links/nytimes_links.nt.bz2) -- Links between New York Times subject headings and DBpedia concepts.
* [DBpedia External references: US Census](http://downloads.dbpedia.org/3.7/links/uscensus_links.nt.bz2) -- inks between US cities and states in DBpedia and data about them from US Census. 
* [DBpedia External references: WordNet](http://downloads.dbpedia.org/3.7/links/wordnet_links.nt.bz2) -- Word Net Synset references, generated by manually relating Wikipedia infobox templates and Word Net synsets, and adding a corresponding link to each thing that uses a specific template. In theory, this classification should be more precise then the Wikipedia category system.

NLP datasets:

* [DBpedia NLP: Lexicalizations Dataset](http://spotlight.dbpedia.org/datasets/lexicalizations_en.nq.bz2)
* [DBpedia NLP: Topic Signatures](http://spotlight.dbpedia.org/datasets/topic_signatures_en.tsv.bz2)
* [DBpedia NLP: Thematic Concept](http://spotlight.dbpedia.org/datasets/topical_concepts.nt.bz2)
* [DBpedia NLP: People's Grammatical Genders](http://spotlight.dbpedia.org/datasets/genders_en.nt.bz2)

Not used:

* [Short Abstracts](http://downloads.dbpedia.org/3.7/en/short_abstracts_en.nq.bz2)
* [Raw Infobox Properties](http://downloads.dbpedia.org/3.7/en/infobox_properties_en.nq.bz2)
* [Raw Infobox Property Definitions](http://downloads.dbpedia.org/3.7/en/infobox_property_definitions_en.nq.bz2)
* many of the "external link" datasets.

Note: Where available we use the "N-Quads" datasets. These include a provenance URI, composed of the URI of the article from Wikipedia where the statement has been extracted; the `absolute-line` in the Wikipedia article source (the first line of a source has the line number 1); the `relative-line` in the Wikipedia article source in respect of the current section; and the `section` inside the article. For Example, in  `http://en.wikipedia.org/wiki/BMW_7_Series#section=E23&relative-line=1&absolute-line=23`
the given statement can be found in the 23rd line overall, in the first line of the section "E23".

## License

DBpedia is derived from Wikipedia and is distributed under the same licensing terms as Wikipedia itself. DBpedia version 3.7 is licensed under the terms of the [Creative Commons Attribution-ShareAlike 3.0 license](http://en.wikipedia.org/wiki/Wikipedia:Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License) and the [GNU Free Documentation License](http://en.wikipedia.org/wiki/Wikipedia:Text_of_the_GNU_Free_Documentation_License).


## Detailed Descriptions

### [DBpedia Core Datasets](http://wiki.dbpedia.org/Datasets?v=x2c)

The core datasets from DBpedia include an ontology to model the extracted information from Wikipedia, general facts about extracted resources, as well as inter-language links. More information on the Core Datasets Page.

If you use DBpedia core data sets in your research, please cite:

> Christian Bizer, Jens Lehmann, Georgi Kobilarov, Sören Auer, Christian Becker, Richard Cyganiak, Sebastian Hellmann: DBpedia - A Crystallization Point for the Web of Data. Journal of Web Semantics: Science, Services and Agents on the World Wide Web, Issue 7, Pages 154-165, 2009.

### [DBpedia NLP Datasets](http://wiki.dbpedia.org/Datasets/NLP?v=xs0)

Each and every dataset from DBpedia is potentially useful for several tasks related to Natural Language Processing (NLP) and Computational Linguistics. We have described in Datasets/NLP a few examples of how to use these datasets. Moreover, we describe a number of extended datasets that were generated during the creation of DBpedia Spotlight and other NLP-related projects.

If you use DBpedia NLP data sets in your research, please cite:

> Pablo N. Mendes, Max Jakob and Christian Bizer. DBpedia for NLP: A Multilingual Cross-domain Knowledge Base. Proceedings of the International Conference on Language Resources and Evaluation, LREC 2012, 21–27 May 2012, Istanbul, Turkey. (to appear)

#### DBpedia NLP: Lexicalizations Dataset

Contains mappings between surface forms and URIs. A surface form is term that has been used to refer to an entity in text. Names and nicknames of people are examples of surface forms. We store the number of times a surface form was used to refer to a DBpedia resource in Wikipedia, and we compute statistics from that. Created by the DBpedia Spotlight team.  Authors: Pablo N. Mendes, Max Jakob.

[Download the DBpedia Lexicalizations Dataset](http://spotlight.dbpedia.org/datasets/)

Example Data:

    dbpedia:Apple_Inc. lexvo:label "Apple computer"@en graph:Apple_Inc.---Apple_computer .
    graph:Apple_Inc.---Apple_computer :pmi “9.867346749590263”^^xsd:double :score .
    dbpedia:Apple_Inc. lexvo:label "Apple, Inc"@en graph:Apple_Inc.---Apple,_Inc .
    graph:Apple_Inc.---Apple,_Inc :pmi "9.867346749590263"^^xsd:double :score .

The data above describes the entity Apple_Inc. and two surface forms used to refer to it: "Apple     Inc." and "Apple computer".

#### DBpedia NLP: Topic Signatures

We tokenize all Wikipedia paragraphs linking to DBpedia resources and aggregate them in a Vector Space Model of terms weighted by their co-occurrence with the target resource. We use those vectors to select the strongest related terms and build topic signatures for those entities. Created by the DBpedia Spotlight team. Authors: Pablo N. Mendes.

[Download the DBpedia Topic Signatures](http://spotlight.dbpedia.org/datasets/)

Example Data:

    Apple_Inc.	+"Apple Inc." computer from mac
    Apple_sauce	+"Apple sauce" pudding butter pie
    Apple_Records	+"Apple Records" beatles album released

#### DBpedia NLP: Thematic Concept

Thematic Concepts are DBpedia resources that are the main subject of a Wikipedia Category. Created by the DBpedia Spotlight team. Authors: Pablo N. Mendes, Max Jakob.

[Download the DBpedia Thematic Concepts](http://spotlight.dbpedia.org/datasets/)

Example Data:

    dbpedia:Adolescence rdf:type skos:Concept
    dbpedia:Adoption rdf:type skos:Concept
    dbpedia:Biodiversity rdf:type skos:Concept

#### DBpedia NLP: People's Grammatical Genders

Can be used for anaphora resolution and coreference resolution tasks. Created by the DBpedia Spotlight team. Authors: Pablo N. Mendes

[Download the DBpedia People's Grammatical Genders](http://spotlight.dbpedia.org/datasets/)

Example Data:

    <http://dbpedia.org/resource/Britney_Spears> :gender :Female
    <http://dbpedia.org/resource/Brigitte_Bardot> :gender :Female
    <http://dbpedia.org/resource/Michiel_Smit> :gender :Male
    <http://dbpedia.org/resource/David_Duke> :gender :Male
    <http://dbpedia.org/resource/Jack_Aubrey> :gender :Male
