require 'telegram/bot'
require "mini_magick"
require 'fileutils'
require "json"
require 'logger'

telegram_api_local = Thread.new{system 'telegram-bot-api --api-id YOUR_ID --api-hash YOUR_HASH --local'}


$pixiv_logger = Logger.new('pixiv_logger.log', 3, 10485760)


def transform_string(input_string)
    input_string.gsub!("&","&amp")
    input_string.gsub!("<",'&lt')
    input_string.gsub!(">","&gt")
    input_string.gsub!(" ","_")
    input_string.strip
end
def getting_comments_message_id(captions_array,message_to_reply_in_comments,comment_chat_id,bot)
    if message_to_reply_in_comments!=0
        p "idk"
        $pixiv_logger.info({message_to_reply_in_comments: message_to_reply_in_comments,comment_chat_id: comment_chat_id})
        return {message_to_reply_in_comments: message_to_reply_in_comments,comment_chat_id: comment_chat_id}
        #temp[:reply_to_message_id]=message_to_reply_in_comments
        #temp[:chat_id]=comment_chat_id
    else
        $pixiv_logger.info("getting message_id in comments")
        #$pixiv_logger.info("image_post=#{image_post}")
        #p image_post
        if false#image_post==false#BUG IDK HOW TO FIX happens with big files
            p "IMAGE_POST==0 !!!!!!!!"
            $pixiv_logger.warn("IMAGE_POST==0 !!!!!!!!")
            $pixiv_logger.info({message_to_reply_in_comments: message_to_reply_in_comments,comment_chat_id: comment_chat_id})
            return {message_to_reply_in_comments: message_to_reply_in_comments,comment_chat_id: comment_chat_id}
        else
            
            #if image_post["result"].class==Hash
            #    image_post_id= image_post["result"]["message_id"]
            #else #else array no other options
            #    image_post_id= image_post["result"][0]["message_id"]
            #end
            #p image_post_id
            #$pixiv_logger.info("image_post_id=#{image_post_id}")
            #p ".....captions_array===#{captions_array}"
            #p captions_array[1]

            $pixiv_logger.info("captions_array=#{captions_array}")
            #$pixiv_logger.info(captions_array)

            bot.listen do |message| 
                #p image_post["result"][0]["message_id"]
                #p message
                #channel post ID
                #next if 
                #next if message.poll
                next if message.class!=Telegram::Bot::Types::Message

                #image_post_id=image_post_id["result"]#[0]#["message_id"]#.message_id
                #p "message.forward_from_message_id=#{message.forward_from_message_id} ____ image_post_id=#{image_post_id}"
                if captions_array[0]=="link"
                    next if message.caption_entities==nil
                    for entitie in message.caption_entities
                        $pixiv_logger.info(entitie)
                        #p entitie
                        #p entitie.url
                        #p captions_array[1]
                        #p entitie.url==captions_array[1]
                        if entitie.url==captions_array[1]
                            #p "YRAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                            #temp[:reply_parameters]={message_id:message.message_id}#,chat_id:comment_chat_id}
                            message_to_reply_in_comments=message.message_id
                            return {message_to_reply_in_comments: message_to_reply_in_comments,comment_chat_id: comment_chat_id}
                            #temp[:reply_to_message_id]=message_to_reply_in_comments
                            #temp[:chat_id]=comment_chat_id
                            break
                        end
                    end
                else
                    $pixiv_logger.info("message.caption=#{message.caption}  captions_array[1]=#{captions_array[1]}")
                    if message.caption==captions_array[1]
                        #temp[:reply_parameters]={message_id:message.message_id}#,chat_id:comment_chat_id}
                        message_to_reply_in_comments=message.message_id
                        return {message_to_reply_in_comments: message_to_reply_in_comments,comment_chat_id: comment_chat_id}
                        #temp[:reply_to_message_id]=message_to_reply_in_comments
                        #temp[:chat_id]=comment_chat_id
                        break
                    end
                end
            end
        end
    end
end

comments_info=0


#telegram_api_local.join
p 'server started'
counter=0
token = PUT TOKEN HERE
channel_id= CHANNEL ID HERE
admin_id=YOUR ID HERE

Dir.mkdir("uploaded") unless File.directory? ("uploaded")
Dir.mkdir("compress") unless File.directory? ("compress")

Telegram::Bot::Client.run(token, url:'http://127.0.0.1:8081') do |bot|#, url:'http://127.0.0.1:8081'
    #bot.listen do |message|
    #    p message
    #end break
    p comment_chat_id=bot.api.get_chat(chat_id:channel_id).linked_chat_id
    p comment_chat_id
    exten=''
    a=Dir.glob("*.{jpg,png,jpeg}")
    result = []
    current_group = []
    

    a.each_with_index do |item, index|
    if index > 0 && item.split("_")[0] == a[index-1].split("_")[0]
        current_group << item
    else
        result << current_group unless current_group.empty?
        current_group = [item]
    end
    end

    result << current_group unless current_group.empty?

    #result << (current_group.length > 1 ? current_group : current_group.first)
    wait_time_in_seconds=30*60
    p result
    p "________________"
    result=result.shuffle
    result=result.shuffle
    p result
    p "-------------"
    time_of_compleation=Time.now+result.length*wait_time_in_seconds
    bot.api.send_message(
        chat_id: admin_id,
        text: "Total posts: #{result.length}\nAproximate time of completion:\n#{time_of_compleation.strftime("%k:%M:%S  %d.%m.%Y")}"
    )
    
    upload_status=0
    upload_array_compressed=[]
    upload_array_original=[]
    image_post=0
    image_post_id=0
    message_to_reply_in_comments=0
    $pixiv_logger.info("Files are ready")
    $pixiv_logger.info("#{result}")
    $pixiv_logger.info("time of completion:#{time_of_compleation.strftime("%k:%M:%S  %d.%m.%Y")}")


    captions_array=[]

    
    result.each do |file|
    begin
        #if file.end_with? ".jpg"
            #exten='image/jpeg'
        #else 
        $pixiv_logger.info("File=#{file}")
        counter+=1
        exten="image/png"
        #end
        img_size=0
        file=file.sort_by {|s| s.split('_p').map(&:to_i) }
        p file
        #p check_image.dimensions
        #p check_image.dimensions.sum

        author_name=""

        if file[0].match?(/[0-9]_p[0-9]*\.(jpg|png|jpeg)/)
            temp_lnk="https://www.pixiv.net/artworks/#{file[0][..file[0].index("_p")-1]}"
            
            resp=Faraday.new(temp_lnk, headers: { 'User-Agent' => 'twitter_images_telegrambot/1.0' }).get.body
            if resp.include? 'favicon.ico"><title>'
                resp= resp[resp.index('favicon.ico"><title>')+10..resp.index(temp_lnk)-1]
                resp= resp[..resp.index(" - pixiv")-1]
                temp_indexes=resp.enum_for(:scan, /(?= - )/).map do
                    Regexp.last_match.offset(0).first
                end
                if resp.include?"のイラスト"
                    author_name=resp[temp_indexes[-1]+3..resp.index("のイラスト")-1]#のマンガ
                else
                    author_name= resp[temp_indexes[-1]+3..resp.index("のマンガ")-1]
                end
                #captions_array
                #author_name= resp[resp.rindex(' - ')+3..]
                author_name="##{transform_string(author_name)}\n"
            else
                author_name="#deleted_artwork\n"
            end
            #if file[0][..file[0].index("_p")-1].to_i>=20
            caption_with_author_name="#{author_name}<a href=\"https://www.pixiv.net/en/artworks/#{file[0][..file[0].index("_p")-1]}\">Source pixiv</a>"
            p caption_with_author_name
            captions_array<<["link","https://www.pixiv.net/en/artworks/#{file[0][..file[0].index("_p")-1]}"]
            $pixiv_logger.info("captions_array_getting_hashtag=#{captions_array}")
            #else
            #    caption_with_author_name="a"
            #    captions_array<<["text","a"]
            #end
            #end
        end


        upload_array_compressed=[]
        upload_array_original=[]
        for file_in_arr in file do
            check_image=MiniMagick::Image.open("#{file_in_arr}")
            mogrify_options='mogrify'
            #p check_image.dimensions.sum
            if check_image.dimensions.sum>9999
                img_size=9000
                mogrify_options+=" -resize 3000x3000"#20000000@" #9000x9000>"
            end
            if check_image.size>5000000
                #system 'mogrify -define jpeg:extent=5000kb -resize '+"#{img_size}x#{img_size}"+' -path compress -format jpg '+ "#{file}" if  !File.exist?('compress\\'+"#{file[..file.index(".")-1]}.jpg")
                mogrify_options+= ' -define jpeg:extent=5000kb'

            end
            check_image=file_in_arr

            #p File.exist?('compress\\'+"#{file_in_arr[..file_in_arr.index(".")-1]}.jpg")

            if mogrify_options!='mogrify'
                if  !File.exist?('compress\\'+"#{file_in_arr[..file_in_arr.index(".")-1]}.jpg")
                    p "compressing #{file_in_arr}"
                    system mogrify_options+=' -path compress -format jpg '+ "\"#{file_in_arr.to_s}\"" 
                end
                check_image='compress\\'+"#{file_in_arr[..file_in_arr.index(".")-1]}.jpg"
            end
            upload_array_compressed << Faraday::UploadIO.new(check_image, exten)
            upload_array_original << Faraday::UploadIO.new(file_in_arr, exten)
            $pixiv_logger.info(upload_array_compressed)
        end
        #p upload_array_compressed
        #p upload_array_original

        current_post=0

        #check if one image or not
        if upload_array_compressed.length==1
            $pixiv_logger.info("upload_array_compressed________1")
            if !(upload_status>current_post)
                if file[0].match?(/[0-9]_p[0-9]*\.(jpg|png|jpeg)/)#(/_p[0-9]+\./)
                    bot.api.send_photo(
                        chat_id: channel_id,
                        photo: upload_array_compressed[0],
                        parse_mode:"HTML",
                        #caption: "#{author_name}[Source pixiv](https://www.pixiv.net/en/artworks/#{file[0][..file[0].index("_p")-1]})"
                        caption: caption_with_author_name
                        )
                    #p post_message_id#=post_message_id.message_id
                    upload_status+=1
                else
                    bot.api.send_photo(
                        chat_id: channel_id,
                        photo: upload_array_compressed[0]
                        )
                    #p post_message_id
                    upload_status+=1
                end
            end
            p "one before"
            upload_array_compressed[0].close
            sleep(2)
            p "one after"
            #upld=Faraday::UploadIO.new(upload_array_original[0], exten)
            
            current_post+=1
            if !(upload_status>current_post)
                if comments_info==0
                    $pixiv_logger.info("getting message id when 1 photo")
                    comments_info=getting_comments_message_id(captions_array[0],message_to_reply_in_comments,comment_chat_id,bot)
                end
                bot.api.send_document(#chat_id:channel_id,
                document: upload_array_original[0],
                reply_to_message_id: comments_info[:message_to_reply_in_comments],
                chat_id: comments_info[:comment_chat_id]
                )
                upload_status+=1
            end
            p "opeee"
            upload_array_original[0].close
        else
            #upload_array.each_slice(10).to_a.each do |array_of_10|
            out_document=[]
            out_photo=[]
            $pixiv_logger.info("upload_array_compressed_______by 10")

            media_photo_request_files=[]
            media_photo_request_media=[]
            media_photo_request_full={
                chat_id: channel_id,
                media: []
            }
            media_document_request_files=[]
            media_document_request_media=[]
            media_document_request_full={
                chat_id: channel_id,
                media: []
            }
            #p upload_array_compressed
            #upload_array_original

            #p upload_array_compressed
            for i in 0..upload_array_compressed.length-1 do
                #out_document<<Telegram::Bot::Types::InputMediaDocument.new(media:upload_array_original[i])
                media_document_request_media<<Telegram::Bot::Types::InputMediaDocument.new(media:"attach://file#{i}")
                media_document_request_files<<Hash[:"file#{i}",Faraday::FilePart.new(upload_array_original[i],exten)]
                if i%10==0 and upload_array_compressed[0].original_filename.match?(/[0-9]_p[0-9]*\.(jpg|png|jpeg)/)
                    sourse=upload_array_compressed[0].original_filename[..upload_array_compressed[0].original_filename.index("_p")-1]
                    #p "_____"+sourse
                    #media_photo_request_media
                    #cptn= i==0 ? caption_with_author_name : "#{i+1}/#{(upload_array_compressed.length-1)/10}\n#{caption_with_author_name}"
                    p "i=#{i}"
                    if i==0
                        cptn=caption_with_author_name
                    else
                        cptn="#{(i+3)/10}/#{(upload_array_compressed.length+1)/10}"
                        captions_array<<["caption",cptn]
                        $pixiv_logger.info("captions_array_upload_array_compressed=#{captions_array}")
                    end
                    media_photo_request_media<<Telegram::Bot::Types::InputMediaPhoto.new(
                        media:"attach://file#{i}",#upload_array_compressed[i],
                        parse_mode:"HTML",
                        caption: cptn
                    )
                    media_photo_request_files << Hash[:"file#{i}",Faraday::FilePart.new(upload_array_compressed[i],exten)]
                else
                    media_photo_request_media<<Telegram::Bot::Types::InputMediaPhoto.new(media:"attach://file#{i}") 
                    #media_photo_request_full[:media]
                    media_photo_request_files<<Hash[:"file#{i}",Faraday::FilePart.new(upload_array_compressed[i],exten)]
                    #media_photo_request_full
                end 
            end
            #p "__-------------------------------------------------------------------------"
            #p "photo:_______"
            #p media_photo_request_media
            #p media_photo_request_files
            #p "_________________________________________________"
            #out_document=out_document.each_slice(10).to_a
            #out_photo=out_photo.each_slice(10).to_a
            media_document_request_files=media_document_request_files.each_slice(10).to_a
            media_document_request_media=media_document_request_media.each_slice(10).to_a
            media_photo_request_media=media_photo_request_media.each_slice(10).to_a
            media_photo_request_files=media_photo_request_files.each_slice(10).to_a

            request_sample={
                chat_id: channel_id,
                media: []
            }




            #p "..................................................."
            #p media_photo_request_files
            #p media_photo_request_files.length
            for i in 0..media_photo_request_files.length-1 do
                #p ",,,,,,,,,,,,,,,,,,,,,,,"
                #p media_photo_request_files[i]
                #p "//////////////////////////"
                #p media_photo_request_media
                if media_photo_request_files[i].length!=1
                    p "here1"
                    $pixiv_logger.info("group photo current_post:#{current_post}/#{upload_status}")
                    #p request_sample.merge(media_photo_request_files[i].inject(&:merge))
                    #p request_sample.merge(media_photo_request_files[i].inject(&:merge))[:media]=media_photo_request_media[i]
                    temp=request_sample.merge(media_photo_request_files[i].inject(&:merge))
                    temp[:media]=media_photo_request_media[i]


                    #p media_photo_request_files

                    current_post+=1

                    if !(upload_status>=current_post)
                        p "upllllllll"
                        bot.api.send_media_group(
                            temp#request_sample.merge(media_photo_request_files[i].inject(&:merge))[:media]=media_photo_request_media[i]
                        )
                        p "upllllllllll___2222222222222222222"
                        upload_status+=1
                        message_to_reply_in_comments=0
                    end
                    
                    sleep(2)
                    p "herrr"
                    $pixiv_logger.info("group document current_post:#{current_post}/#{upload_status}")
                    temp= request_sample.merge(media_document_request_files[i].inject(&:merge))
                    temp[:media]=media_document_request_media[i]
                    #p media_document_request_media


                    #COMMENTS SEND UNCOMPRESSED
                    if media_document_request_media[0].length>=-1
                        #p image_post_id
                        
                        
                        current_post+=1
                        $pixiv_logger.info("uploading documents in comments current_post:#{current_post}/#{upload_status}")
                        if !(upload_status>=current_post)
                            p "comments_info=#{comments_info}"
                            if comments_info==0
                                $pixiv_logger.info("getting message id when many photo")
                                comments_info=getting_comments_message_id(captions_array[i],message_to_reply_in_comments,comment_chat_id,bot)
                            end
    
                            temp[:reply_to_message_id]=comments_info[:message_to_reply_in_comments]
                            temp[:chat_id]=comments_info[:comment_chat_id]
                            bot.api.send_media_group(
                                temp#request_sample.merge(media_document_request_files[i].inject(&:merge))[:media]=media_document_request_media[i]
                            )
                            upload_status+=1
                        end
                        

                    else #can not reach here bc -1 above
                        current_post+=1
                        $pixiv_logger.info("uploading documents current_post:#{current_post}/#{upload_status}")
                        if !(upload_status>=current_post)
                            bot.api.send_media_group(
                                temp#request_sample.merge(media_document_request_files[i].inject(&:merge))[:media]=media_document_request_media[i]
                            )
                            upload_status+=1
                        end
                    end
                else
                    p "here2"
                    $pixiv_logger.info("captions_array in rest phoro=#{captions_array}")
                    upload_array_compressed[0].close
                    upload_array_original[0].close
                    $pixiv_logger.info("uploading single photo and document THE REST current_post:#{current_post}/#{upload_status}")
                    upload_array_compressed[0]= Faraday::UploadIO.new(check_image, exten)
                    upload_array_original[0]= Faraday::UploadIO.new(file_in_arr, exten)
                    current_post+=1
                    if !(upload_status>=current_post)
                        image_post=bot.api.send_photo(
                            chat_id: channel_id,
                            photo: upload_array_compressed[0],
                            caption: captions_array[-1][1]
                        )
                        upload_status+=1
                        message_to_reply_in_comments=0
                    end



                    sleep(2)
                    current_post+=1
                    if !(upload_status>=current_post)
                        if comments_info==0
                            $pixiv_logger.info("getting message id when rest 1 photo")
                            comments_info=getting_comments_message_id(captions_array[i],message_to_reply_in_comments,comment_chat_id,bot)
                        end
                        bot.api.send_document(#chat_id:channel_id,
                        document: upload_array_original[0],
                        reply_to_message_id: comments_info[:message_to_reply_in_comments],
                        chat_id: comments_info[:comment_chat_id]
                        )
                        upload_status+=1
                    end
                    upload_array_compressed[0].close
                    upload_array_original[0].close
                    upload_array_compressed-=[upload_array_compressed[0]]
                    upload_array_original-=[upload_array_original[0]]
                end
                #comments_info=0#to send uncompressed when single
            end
        end
       # p "---"
        #p upload_array_compressed
        #p upload_array_original
        #p "____"
        #$pixiv_logger.info("closing all IO streams total=#{upload_array_compressed.length}")
        for i in 0..upload_array_compressed.length-1 do
            upload_array_compressed[i].close
            upload_array_original[i].close
        end
        p "transfer"
        
        #result.delete(file) BAD DONT USE
        result-= [file]
        file.each do |ff|
            FileUtils.mv(ff, "uploaded/#{ff}")
        end
        sleep(wait_time_in_seconds)
        captions_array=[]
        comments_info=0
        upload_status=0
        image_post=0
        image_post_id=0
        message_to_reply_in_comments=0
    end

    rescue Exception=> e
        p e
        $pixiv_logger.warn("#{e}")
        $pixiv_logger.fatal("#{e}\n#{e.backtrace}")
        for i in 0..upload_array_compressed.length-1 do
            upload_array_compressed[i].close
            upload_array_original[i].close
        end
        case e.to_s
        when /Internal Server Error/
            sleep(1)
            retry
        when /Too Many Requests: retry after/
            p e.to_s
            ttt=e.to_s[e.to_s.index("parameters: {\"retry_after\"=>")+29..e.to_s.index('})')-1]
            sleep(ttt.to_i)
            retry
        when /SSL_connect returned=1/
            $pixiv_logger.warn("SSL_connect returned 1")
            sleep(2)
            retry
        when /Net::ReadTimeout/
            upload_status+=1
            sleep(1)
            retry
        when /Failed to open TCP/
            sleep(2)
            retry
        end
        File.write("#{Time.now.to_i}.txt", "#{Time.now}\n #{e}\n#{e.backtrace}\n#{result}")
    end

    bot.api.send_message(
          chat_id: admin_id,
          text: "finnished, uploaded #{counter} posts"
        )
    telegram_api_local.exit
end

=begin
uploaded_files=[]
db.execute( "select * from uploaded" ) do |row|
    uploaded_files+=row
end

Dir.glob("*.{jpg,png,jpeg}").each do |file|
    FileUtils.mv(file, "uploaded/#{file}") if uploaded_files.include? file
end
p "finnish, clearing DB"
db.execute("DELETE FROM uploaded")
p "DB deleted"
p "fins"
=end
