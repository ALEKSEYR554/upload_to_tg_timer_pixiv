Place this in the same folder as pixiv images(AKA named artwork_id _p NUMBER). Declare the variables in lines 101-103 to make it work

Install mini_magick and telegram/bot gems. Install ImageMagick with legacy to compress files

Uploads all artworks with the same artwork_id and different NUMBER in a separate post. Tested with 30+ NUMBER. Adds author hashtag and link to artwork to the first post.

You MUST add bot to comment section of channel to upload uncompressed files

Suggest using local API to be able to upload large files with no problems
