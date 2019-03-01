/**
 * Created by dave on 2017/10/20.
 */

var nodejieba = require("nodejieba");
nodejieba.load({
    userDict: './library/userdict.utf8'
})
var result = nodejieba.cut("iphone8 运行大型3D游戏，对比上一代 iphone7 有哪些升级");
console.log(result);
//["南京市","长江大桥"]