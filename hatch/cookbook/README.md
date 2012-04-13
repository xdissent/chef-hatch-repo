Description
===========

This cookbook contains a single recipe, which dumps a JSON representation 
of the node to a tmp file. The hatch:finish rake task will then save this 
node data on the (now running) Chef server.

Do not use this cookbook directly. The appropriate run_list entries will
be created automatically when hatching as server.
