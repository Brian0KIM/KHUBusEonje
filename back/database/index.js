const session=[];
const setSession = function(id,cookie) { 
    //중복 로그인시 최근 로그인 정보를 덮어씀
    const sessionAvaliable = session.find(user => user.id === id);
    if (!sessionAvaliable) {
    session.push({
        id: id,
        Cookie: cookie,
        reserveReserve: []
    });}
    else {
        sessionAvaliable.Cookie = cookie;
    }
}
const setSession2 = function(id, cookie) {
    const sessionAvaliable = session.find(user => user.id === id);
    if (sessionAvaliable) {
        sessionAvaliable.Cookie2 = cookie
    }
}

const getSession = function(id) {
    return session.find(user => user.id == id)['Cookie'];
}
const getSession2 = function(id) {
    return session.find(user => user.id == id)['Cookie2'];
}
const getSession3= function(id) {
    return session.find(user => user.id == id)['reserveReserve'];
}
process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = 0;

const request = require('request')

function getpublickey(callback) {
    request.get({uri:'https://lib.khu.ac.kr/login'}, function(err, res, body) {
        const cookie = res.headers['set-cookie']

        let data = body.split("encrypt.setPublicKey('")[1]
        data = data.split("'")[0]
        callback(data, cookie)
    })
}

const JSEncrypt = require('node-jsencrypt');

function login(id, pw, callback, ecallback) {
    getpublickey((key, cookie) => {
        let enc = new JSEncrypt()
        enc.setPublicKey(key)
        let encid = enc.encrypt(id)
        let encpw = enc.encrypt(pw)

        request.post({
            url: 'https://lib.khu.ac.kr/login',
            followAllRedirects: true,
            'Content-type': 'application/x-www-form-urlencoded',
            headers: {
                'User-Agent': 'request',
                Cookie: cookie
            },
            form: {
                encId: encid,
                encPw: encpw,
                autoLoginChk: 'N'
            }
        }, function(err, res, body) {
            if (err) {
                console.log('err', err)
                ecallback(err)
                return
            }
            
            let data = body
            data = data.split('<p class="userName">')
            if (data.length == 1) {
                console.log('login failed')
                ecallback('login failed')
                return
            }   
            data = data[2]
            data = data.split('<span class="name">')[1]
            data = data.split('</span>')[0]

            data = data.split(')')[0]
            let [name, id] = data.split('(')
            
            callback({name: name, id: id}, cookie)
        })
    })
}

function getMID(cookie, callback, ecallback) {
    request.get({
        url: 'https://lib.khu.ac.kr/relation/mobileCard',
        followAllRedirects: false,
        headers: {
            'User-Agent': 'request',
            Cookie: cookie
        }
    }, function(err, res, body) {
        if (err) {
            console.log('err', err)
            ecallback(err)
            return
        }

        let mid = body
        mid = mid.split('<input type="hidden" name="mid_user_id" value="')
        if (mid.length == 1) {
            console.log('err: cannot get MID')
            ecallback(err)
            return
        }
        mid = mid[1]
        mid = mid.split('"')[0]
        callback(mid)
    })
}

function getUserInfo(cookie, callback, ecallback) {
    request.get({
        url: 'https://libseat.khu.ac.kr/user/my-status',
        headers: {
            'User-Agent': 'request',
            Cookie: cookie
        }
    }, function(err, res, body) {
        if (err) {
            console.log('err at getUserInfo', err)
            ecallback(err)
            return
        }

        callback(JSON.parse(body))
    })
}
module.exports = {
    login,getMID, setSession, getSession, setSession2, getSession2, getUserInfo, getSession3
};