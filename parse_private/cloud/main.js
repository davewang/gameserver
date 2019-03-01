const HttpUtils = require('./untils/httpServer.js')
Parse.Cloud.define('hello', function(req, res) {
  res.success('Hi');
});
var Author = "Author";
var Album = "Album";
var Video = "Video";
var cutAble = true;

//var kue = require('kue-scheduler');
var nodejieba = require("nodejieba");
nodejieba.load({
    userDict: './library/userdict.utf8'
})
// var result = nodejieba.cut("蒲公英泡水千万不能这么喝，看完吓出一身冷汗");
// console.log(result);



/*
 curl -X POST \
 -H "X-Parse-Application-Id: YKjNQyNBBsaJpRlcSRxBfR3yKCGdU395XzZfqjdB" \
 -H "X-Parse-REST-API-Key: JBDMxg9uyvbq7FQdd44EtSKDLdDlIrRrP6EIvFZJ" \
 -H "Content-Type: application/json" \
 -d '{"exportClass": "MyClass"}' \
 https://parseapi.back4app.com/functions/export > out.json
 */
Parse.Cloud.define("export", function(request, response) {
    var ExportObject = Parse.Object.extend(request.params.exportClass);
    var query = new Parse.Query(ExportObject);
    query.find({ success: response.success, error: response.error });
});
/*
curl -X POST \
-H "X-Parse-Application-Id: LL9oIdzIkmwl5xyowQQu0fTmXyUWfet9RuAzwHfj" \
-H "X-Parse-REST-API-Key: R3S8PYQKuzeV4c8MUeO5ved46C50MEp56boDHW1O" \
-H "Content-Type: application/json" \
-d @data.json \
https://parseapi.back4app.com/functions/import

data.json
 {
 "className": "ExampleClass",
 "rows": [
 { "ExampleColumnA": "row1columnA", "ExampleColumnB": "row1columnB" },
 { "ExampleColumnA": "row2columnA", "ExampleColumnB": "row2columnB"}
 ]
 }
*/

Parse.Cloud.define("import", function (request, response) {
    var className = request.params.className;
    var rows = request.params.rows;

    var MyClass = Parse.Object.extend(className);

    var promises = [];
    for (var i = 0; i < rows.length; i++) {
        var myClassObject = new MyClass();

        for (var column in rows[i]) {
            myClassObject.set(column, rows[i][column]);
        }

        promises.push(myClassObject.save());
    }

    Parse.Promise
        .when(promises)
        .then(
            function () {
                response.success('Successfully imported ' + i + ' rows into ' + className + ' class');
            },
            function (error) {
                response.error('Import failed: ' + error);
            });
});
//保存author
function addAuthor(author,cb) {
    //console.log("addAuthor start author.id = "+author.id);
    var AuthorClass = Parse.Object.extend(Author);
    var query = new Parse.Query(AuthorClass);
    query.equalTo("sourceId", author.id);
    query.first({
        success: function(object) {
            // Successfully retrieved the object.
            if (object == undefined )
            {
                var newObject = new AuthorClass();
                newObject.set("name",author.name);
                newObject.set("sourceId",author.id);
                newObject.set("avatar",author.avatar);
                newObject.save(null, {
                    success: function(newObject) {
                        // Execute any logic that should take place after the object is saved.
                        //console.log('New object created with objectId: ' + newObject.id);
                        cb(newObject)

                    },
                    error: function(gameScore, error) {
                        // Execute any logic that should take place if the save fails.
                        // error is a Parse.Error with an error code and message.
                        console.log('Failed to create new object, with error code: ' + error.message);
                        cb(null)
                    }
                });
            }else{
                cb(object)

            }
            //cb(object)
            //console.log("addAuthor end "+object);
        },
        error: function(error) {
            console.log("Error: " + error.code + " " + error.message);
            //console.log("addAuthor end");
            cb(null)


        }
    });
}
//保存相册
function addAlbum(album,author,cb) {
    var AlbumClass = Parse.Object.extend(Album);
    //console.log("addAlbum start");
    var query = new Parse.Query(AlbumClass);
    query.equalTo("sourceId", album.id);
    query.first({
        success: function(object) {
            // Successfully retrieved the object.

            if (object == undefined)
            {

                var newObject = new AlbumClass();
                newObject.set("uuid",album.uuid);
                newObject.set("sourceId",album.id);
                newObject.set("content",album.content);
                newObject.set("addTime",parseInt(album.addTime));
                newObject.set("styleId",album.styleId);
                newObject.set("type",album.type);
                newObject.set("photos",album.photos);
                newObject.set("author",author);
                //console.log(newObject);
                newObject.save(null, {
                    success: function(newObject) {
                        // Execute any logic that should take place after the object is saved.
                        //console.log('New object created with objectId: ' + newObject.id);
                        cb(newObject);
                        //console.log("addAlbum end");

                    },
                    error: function(gameScore, error) {
                        // Execute any logic that should take place if the save fails.
                        // error is a Parse.Error with an error code and message.
                        console.log('Failed to create new object, with error code: ' + error.message);
                        cb(null);
                        //console.log("addAlbum end");
                    }
                });
            }else {

                cb(object);
            }
            // console.log('album sourceId: ' + newObject.id+" is exist!");
            // console.log("addAlbum end");
        },
        error: function(error) {
            console.log("Error: " + error.code + " " + error.message);
            cb(null)
        }
    });
}
function parseAlbum(album,cb) {

    //console.log("parseAlbum start");
    //添加作者
    addAuthor( album.girl,function (author) {
        if (author!=null)
        {
            //添加相册
            addAlbum(album,author,cb)
        }
    })

}

function doLoopAlbums(page,cb) {

    Parse.Cloud.httpRequest({
        url: 'http://apiv2.prettybeauty.biz/album/all?app=Rosi&pageIndex='+page,
        headers: {
            'User-Agent': 'Beauty/2.6 (iPhone; iOS 10.3.2; Scale/2.00)'
        }
    }).then(function(httpResponse) {
        console.log("page = "+page);
        //console.log("httpResponse.text = "+httpResponse.text);
        var newPage = page+1;
        var jsonData = JSON.parse(httpResponse.text);
        var objects = jsonData.data.albums;
       //if(objects.length > 0 && newPage < 20)
        if(objects.length > 0 )
        {
            var counts = 0;
            var saved = [];
            function importDataSuccessCallBack(__cb) {
                doLoopAlbums(newPage,__cb)
            }
            function parse(index, _cb) {
                if(index == objects.length) {
                    //_cb(httpResponse,saved);
                    importDataSuccessCallBack(_cb)
                }else{
                    parseAlbum(objects[index],function(newAlbum) {
                        index = index+1;
                        parse(index,_cb)
                    });
                }
            }
            parse(counts,cb)
        }else {
            cb(httpResponse);

        }
       // console.log(objects.length);

       // console.log(httpResponse.text);
        //cb(httpResponse)
    }, function(httpResponse) {
        console.error('Request failed with response code ' + httpResponse.status);
        cb(httpResponse)
    });

}


Parse.Cloud.job("getAlbums", function(request, status) {
    // the params passed through the start request
    const params = request.params;
    // Headers from the request that triggered the job
    const headers = request.headers;

    // get the parse-server logger
    const log = request.log;

    // Update the Job status message
    status.message("正在抓取中...");
    doLoopAlbums(1,function (httpResponse) {
       if(httpResponse.status==200)
       {
           status.success("抓取完成");
           //console.log(httpResponse.text)
       }else{
           status.error("抓取发生错误");
       }
    });

});

//
//
// var start_urls = [
//   //  {"type": "1", "uri": "http://v.d.aabbuid.com:8090/videos?tag=YOgKcG8C4zc"} //,
//     // {"type": "2", "uri": "http://v.d.aabbuid.com:8090/videos?tag=kaVqg6YOEuk"} ,
//     // {"type": "3", "uri": "http://v.d.aabbuid.com:8090/videos?tag=aAwsokgc84T"} ,
//     // {"type": "4", "uri": "http://v.d.aabbuid.com:8090/videos?tag=kbqqg6YOEuk"} ,
//      {"type": "5", "uri": "http://v.d.aabbuid.com:8090/videos?tag=aAwsokgc84I"} //,
//    // {"type": "6", "uri": "http://v.d.aabbuid.com:8090/videos?tag=EKo2In86Mq4"} ,
//    // {"type": "7", "uri": "http://v.d.aabbuid.com:8090/videos?tag=JmZAbOp-x8L"}
// ];
//
// var cmp = '';
// function parseResp(url, cb) {
//
//     var curl = url+"&zzz="+new Date().getTime();
//     console.log(curl);
//     Parse.Cloud.httpRequest({
//         url: curl
//     }).then(function(httpResponse) {
//         var content = httpResponse.text;
//         if(httpResponse.status == 200)
//         {
//            if (cmp == content)
//            {
//                cb(null)
//            }else {
//                cb(content)
//            }
//         }
//
//     }, function(httpResponse) {
//         console.error('Request failed with response code ' + httpResponse.status);
//         cb(null)
//     });
//
// }
// function importData(data,cb)
// {
//   //console.log(data)
//   function addRowData(video,cb) {
//       var VideoClass = Parse.Object.extend(Video);
//       var query = new Parse.Query(VideoClass);
//       query.equalTo("sourceId", video.sid);
//       query.first({
//           success: function(object) {
//               // Successfully retrieved the object.
//               if (object == undefined )
//               {
//                   var newObject = new VideoClass();
//                   newObject.set("title",video.name);
//                   newObject.set("sourceId",video.sid);
//                   newObject.set("description",video.desc);
//                   newObject.set("mp4url",video.video.url);
//                   newObject.set("cover","http://di.aabbuid.com:8090/thumb/375/211/1/"+video.coverImg.sid+"/"+video.coverImg.sid+video.coverImg.dotExt);
//                   newObject.save(null, {
//                       success: function(newObject) {
//                           // Execute any logic that should take place after the object is saved.
//                           console.log('New object created with objectId: ' + newObject.id);
//                           cb(newObject)
//
//                       },
//                       error: function(gameScore, error) {
//                           // Execute any logic that should take place if the save fails.
//                           // error is a Parse.Error with an error code and message.
//                           console.log('Failed to create new object, with error code: ' + error.message);
//                           cb(null)
//                       }
//                   });
//               }else{
//                   cb(object)
//
//               }
//               //cb(object)
//               //console.log("addAuthor end "+object);
//           },
//           error: function(error) {
//               console.log("Error: " + error.code + " " + error.message);
//               console.log("addvideo end");
//               cb(null)
//           }
//       });
//   }
//     var objects = data;
//     console.log(objects.length )
//     if(objects.length > 0)
//     {
//         var counts = 0;
//         function parse(index, _cb) {
//             if(index == objects.length) {
//                 _cb(true)
//             }else{
//                 addRowData(objects[index],function(newAlbum) {
//                     index = index+1;
//                     parse(index,_cb)
//                 });
//             }
//         }
//         parse(counts,cb)
//     }else {
//         cb(true);
//
//     }
//
//
// }
// var parser = require('xml2json');
// function startParse(url,cb)
// {
//     // for(var index in start_urls)
//   //  {
//        var page = 1;
//        function callback(content) {
//
//            if (content!=null)
//            {
//                cmp=content;
//                page = page+1;
//                var jsonData;
//                try
//                {
//                    jsonData = JSON.parse(content)
//                }
//                catch(err)
//                {
//                    jsonData = parser.toJson(content);
//                }
//                importData(jsonData,function (result) {
//                    parseResp(url+"&page="+page,callback)
//                })
//
//
//
//            }else {
//                cb(true)
//            }
//        }
//        parseResp(url+"&page="+page,callback)
//   //  }
// }
//
// function hasNextUrl(index,cb) {
//     if(index == start_urls.length) {
//         //_cb(httpResponse,saved);
//         //importDataSuccessCallBack(_cb)
//
//         cb(true)
//     }else{
//         function _cb(end) {
//             if(end){
//                 index = index+1;
//                 hasNextUrl(index,cb)
//             }
//         }
//         cmp = '';
//         startParse(start_urls[index].uri,_cb);
//     }
// }


function addVideo(video,type,author,cb) {
      var VideoClass = Parse.Object.extend(Video);
      var query = new Parse.Query(VideoClass);
      query.equalTo("sourceId", video.vid);
      query.first({
          success: function(object) {
              // Successfully retrieved the object.
              if (object == undefined )
              {
                  var newObject = new VideoClass();
                  newObject.set("title",video.title);
                  newObject.set("sourceId",video.vid);
                  newObject.set("description",video.description);
                  newObject.set("mp4url",video.mp4_url);
                  newObject.set("cover",video.cover);
                  newObject.set("ptime",video.ptime);
                  newObject.set("author",author);
                  newObject.set("type",type);
                  if (cutAble == true) {
                      var result = nodejieba.cut(video.title);
                      console.log(result);
                      newObject.set("tags",result);
                  }

                  newObject.save(null, {
                      success: function(newObject) {
                          // Execute any logic that should take place after the object is saved.
                          //console.log('New object created with objectId: ' + newObject.id);
                          cb(newObject)

                      },
                      error: function(gameScore, error) {
                          // Execute any logic that should take place if the save fails.
                          // error is a Parse.Error with an error code and message.
                          console.log('Failed to create new object, with error code: ' + error.message);
                          cb(null)
                      }
                  });
              }else{
                  cb(object)

              }
              //cb(object)
              //console.log("addAuthor end "+object);
          },
          error: function(error) {
              console.log("Error: " + error.code + " " + error.message);
              //console.log("addvideo end");
              cb(null)
          }
      });
}
function doLoopVideos(_type,_page, cb) {

    var id;
    var type = parseInt(_type) || 0;
    var page = parseInt(_page) || 0;
    // 0搞笑视频  1美女视频  2体育视频  3 新闻现场 4涨姿势  5猎奇  6 黑科技 默认搞笑视频
    switch (type) {
        case 0:
            id = "VAP4BFE3U";
            break;
        case 1:
            id = "VAP4BG6DL";
            break;
        case 2:
            id = "VBF8F2E94";
            break;
        case 3:
            id = "VAV3H6JSN";
            break;
        case 4:
            id = "VBF8F3SGL";
            break;
        case 5:
            id = "VBF8ET3S2";
            break;
        case 5:
            id = "VBF8F2PKF";
            break;
        default:
            id = "VAP4BFE3U";
    }

    var host = "c.m.163.com";
    var index = page > 1 ? (page-1)*10+1 : page
  //  var path = `/nc/video/list/${id}/y/${page}-10.html`;
    var path = `/nc/video/list/${id}/y/${index}-10.html`;
    var data = {};
    //false:http请求  true:https请求
    //console.log(path);
    HttpUtils.httpGet(host, data, path, false).then(function(body) {
        // res.send({
        //     msg: "success",
        //     code: 1,
        //     data: JSON.parse(body)[id]
        // })

        var objects = JSON.parse(body)[id];
        if(objects.length > 0 && page < 20)
        {
            var counts = 0;
            var saved = [];
            function importDataSuccessCallBack(__cb) {
                doLoopVideos(_type,(1+page)+"",__cb)
            }
            function parse(index, _cb) {
                if(index == objects.length) {
                    //_cb(httpResponse,saved);
                    importDataSuccessCallBack(_cb)
                }else{
                    parseVideo(objects[index],_type,function(newAlbum) {
                        index = index+1;
                        parse(index,_cb)
                    });
                }
            }
            parse(counts,cb)
        }else {
            cb(null);

        }

    }).catch(function(err) {
        // res.send({
        //     msg: "糟糕!!! 网络好像有点问题",
        //     code: 0
        // })
        console.log(err)
        cb(null)
    })
}
function parseVideo(video,type,cb) {

    //console.log("parseAlbum start");
    //添加作者

    var author = {id:video.topicSid,avatar:video.topicImg,name:video.topicName};

    addAuthor(author,function (author) {
        if (author!=null)
        {
            //添加视频
            addVideo(video,type,author,cb)
        }
    })

}
//
// Parse.Cloud.job("抓搞笑视频", function(request, status) {
//     // the params passed through the start request
//     const params = request.params;
//     // Headers from the request that triggered the job
//     const headers = request.headers;
//
//     // get the parse-server logger
//     const log = request.log;
//
//     // Update the Job status message
//     status.message("正在抓取中...");
//
//     //var startIndex = 0;
//     doLoopVideos('0','1',function (httpResponse) {
//         status.success("抓取完成");
//
//     });
// });
//
//
// Parse.Cloud.job("抓美女视频", function(request, status) {
//     // the params passed through the start request
//     const params = request.params;
//     // Headers from the request that triggered the job
//     const headers = request.headers;
//
//     // get the parse-server logger
//     const log = request.log;
//
//     // Update the Job status message
//     status.message("正在抓取中...");
//
//     //var startIndex = 0;
//     doLoopVideos('1','1',function (httpResponse) {
//         status.success("抓取完成");
//     });
// });
// Parse.Cloud.job("抓体育视频", function(request, status) {
//     // the params passed through the start request
//     const params = request.params;
//     // Headers from the request that triggered the job
//     const headers = request.headers;
//
//     // get the parse-server logger
//     const log = request.log;
//
//     // Update the Job status message
//     status.message("正在抓取中...");
//
//     //var startIndex = 0;
//     doLoopVideos('2','1',function (httpResponse) {
//         status.success("抓取完成");
//     });
// });
// Parse.Cloud.job("抓新闻视频", function(request, status) {
//     // the params passed through the start request
//     const params = request.params;
//     // Headers from the request that triggered the job
//     const headers = request.headers;
//
//     // get the parse-server logger
//     const log = request.log;
//
//     // Update the Job status message
//     status.message("正在抓取中...");
//
//     //var startIndex = 0;
//     doLoopVideos('3','1',function (httpResponse) {
//         status.success("抓取完成");
//     });
// });
// Parse.Cloud.job("抓涨姿势视频", function(request, status) {
//     // the params passed through the start request
//     const params = request.params;
//     // Headers from the request that triggered the job
//     const headers = request.headers;
//
//     // get the parse-server logger
//     const log = request.log;
//
//     // Update the Job status message
//     status.message("正在抓取中...");
//
//     //var startIndex = 0;
//     doLoopVideos('4','1',function (httpResponse) {
//         status.success("抓取完成");
//     });
// });
// Parse.Cloud.job("抓猎奇视频", function(request, status) {
//     // the params passed through the start request
//     const params = request.params;
//     // Headers from the request that triggered the job
//     const headers = request.headers;
//
//
//     // get the parse-server logger
//     const log = request.log;
//
//     // Update the Job status message
//     status.message("正在抓取中...");
//
//     //var startIndex = 0;
//     doLoopVideos('5','1',function (httpResponse) {
//         status.success("抓取完成");
//     });
// });
//
// Parse.Cloud.job("抓黑科技视频", function(request, status) {
//     // the params passed through the start request
//     const params = request.params;
//     // Headers from the request that triggered the job
//     const headers = request.headers;
//
//     // get the parse-server logger
//     const log = request.log;
//
//     // Update the Job status message
//     status.message("正在抓取中...");
//
//     //var startIndex = 0;
//     doLoopVideos('6','1',function (httpResponse) {
//         status.success("抓取完成");
//     });
// });



Parse.Cloud.job("getVideos", function(request, status) {
    // the params passed through the start request
    const params = request.params;
    // Headers from the request that triggered the job
    const headers = request.headers;

    // get the parse-server logger
    const log = request.log;

    // Update the Job status message
    status.message("正在抓取搞笑中...");

    doLoopVideos('0','1',function (httpResponse) {
        status.message("正在抓取美女中...");
        doLoopVideos('1','1',function (httpResponse) {
            status.message("正在抓取体育中...");
            doLoopVideos('2','1',function (httpResponse) {
                status.message("正在抓取新闻中...");
                doLoopVideos('3','1',function (httpResponse) {
                    status.message("正在抓取涨姿势中...");
                    doLoopVideos('4','1',function (httpResponse) {
                        status.message("正在抓取猎奇中...");
                        doLoopVideos('5','1',function (httpResponse) {
                            status.message("正在抓取黑科技中...");
                            doLoopVideos('6','1',function (httpResponse) {
                                status.success("抓取完成.");

                            });

                        });

                    });

                });

            });

        });

    });
});

/*
 Relational Queries

 There are several ways to issue queries for relational data.
  If you want to retrieve objects where a field matches a particular object,
  you can use a where clause with a Pointer encoded with __type just like you would use other data types. For example,
   if each Comment has a Post object in its post field, you can fetch comments for a particular Post:

 该帖子的所以评论
 curl -X GET \
 -H "X-Parse-Application-Id: ${APPLICATION_ID}" \
 -H "X-Parse-REST-API-Key: ${REST_API_KEY}" \
 -G \
 --data-urlencode 'where={"post":{"__type":"Pointer","className":"Post","objectId":"8TOXdXf3tz"}}' \
 https://api.parse.com/1/classes/Comment



 得到所以喜欢该帖子的用户

 curl -X GET \
 -H "X-Parse-Application-Id: ${APPLICATION_ID}" \
 -H "X-Parse-REST-API-Key: ${REST_API_KEY}" \
 -G \
 --data-urlencode 'where={"$relatedTo":{"object":{"__type":"Pointer","className":"Post","objectId":"8TOXdXf3tz"},"key":"likes"}}' \
 https://api.parse.com/1/users

最后的10条评论，并包含所属的帖子

 curl -X GET \
 -H "X-Parse-Application-Id: ${APPLICATION_ID}" \
 -H "X-Parse-REST-API-Key: ${REST_API_KEY}" \
 -G \
 --data-urlencode 'order=-createdAt' \
 --data-urlencode 'limit=10' \
 --data-urlencode 'include=post' \
 https://api.parse.com/1/classes/Comment


 多级包括

 curl -X GET \
 -H "X-Parse-Application-Id: ${APPLICATION_ID}" \
 -H "X-Parse-REST-API-Key: ${REST_API_KEY}" \
 -G \
 --data-urlencode 'order=-createdAt' \
 --data-urlencode 'limit=10' \
 --data-urlencode 'include=post.author' \
 https://api.parse.com/1/classes/Comment

 */
//var kue = require('kue-scheduler');
//var kue = require('kue-scheduler');
//console.log(kue)
//var Queue = kue.createQueue();
Parse.Cloud.job("计划任务", function(request, status) {
    // the params passed through the start request
    const params = request.params;
    // Headers from the request that triggered the job
    const headers = request.headers;

    // get the parse-server logger
    const log = request.log;

    // Update the Job status message
    status.message("计划开始...");

   //var Queue = kue.createQueue({jobEvents: false});
    //create a job instance
    // var albumJob = Queue
    //     .createJob('album_every',  {})
    //     .attempts(3)
    //     .backoff( {})
    //     .priority('normal')
    //     .unique('album_every');
    //
    // var videoJob = Queue
    //     .createJob('video_every', {})
    //     .attempts(3)
    //     .backoff( {})
    //     .priority('normal')
    //     .unique('video_every');
    //
    // //schedule it to run every 10 seconds
    // Queue.every('14400 seconds', albumJob);
    //
    // //schedule it to run every 10 seconds
    // Queue.every('10800 seconds', videoJob);
    //
    // //somewhere process your scheduled jobs
    // Queue.process('album_every', function(job, done) {
    //
    //     status.message("开始抓取图片：",new Date());
    //     doLoopAlbums(1,function (httpResponse) {
    //         if(httpResponse.status==200)
    //         {
    //             status.message("抓取图片完成");
    //             done();
    //             //console.log(httpResponse.text)
    //         }else{
    //             status.message("抓取图片发生错误");
    //             done();
    //         }
    //     });
    //
    // });
    // //somewhere process your scheduled jobs
    // Queue.process('video_every', function(job, done) {
    //     status.message("开始抓取视频：",new Date());
    //    // console.log("video_every run",new Date());
    //
    //
    //     doLoopVideos('0','1',function (httpResponse) {
    //         status.message("正在抓取美女中...");
    //         doLoopVideos('1','1',function (httpResponse) {
    //             status.message("正在抓取体育中...");
    //             doLoopVideos('2','1',function (httpResponse) {
    //                 status.message("正在抓取新闻中...");
    //                 doLoopVideos('3','1',function (httpResponse) {
    //                     status.message("正在抓取涨姿势中...");
    //                     doLoopVideos('4','1',function (httpResponse) {
    //                         status.message("正在抓取猎奇中...");
    //                         doLoopVideos('5','1',function (httpResponse) {
    //                             status.message("正在抓取黑科技中...");
    //                             doLoopVideos('6','1',function (httpResponse) {
    //                                 status.message("抓取视频完成.");
    //                                 done();
    //
    //                             });
    //
    //                         });
    //
    //                     });
    //
    //                 });
    //
    //             });
    //
    //         });
    //
    //     });
    // });

});



//Parse.Cloud.afterSave("Album", function(request) {
    //console.log(request.operation.op("likes"))
//    console.log(JSON.stringify( request ))
    // const query = new Parse.Query("Post");
    // query.get(request.object.get("post").id)
    //     .then(function(post) {
    //         post.increment("comments");
    //         return post.save();
    //     })
    //     .catch(function(error) {
    //         console.error("Got an error " + error.code + " : " + error.message);
    //     });
//});


