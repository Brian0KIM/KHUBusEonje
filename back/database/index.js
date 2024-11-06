
const xml2js2 = require('xml2js');
const session=[];
const setSession = function(id, name, cookie) { 
    const sessionAvaliable = session.find(user => user.id === id);
    if (!sessionAvaliable) {
        session.push({
            id: id,
            name: name,           // 이름 추가
            Cookie: cookie
        });
    } 
    else {
        sessionAvaliable.Cookie = cookie;
        sessionAvaliable.name = name;  // 이름 업데이트
    }
}
const getUserSession = function(id) {
    return session.find(user => user.id == id);
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
const bus = {
    lastUpdate: null,
    currentData: null,
    updateInterval: null
};

function mybusinfo(routeId, callback, ecallback) {
    const url = 'http://apis.data.go.kr/6410000/buslocationservice/getBusLocationList';
    const serviceKey = 'YijIcFf7g0uISm%2BdQdDk5pw7WfFbMyqPPo9So6Jyxck0kr1YMHzTPR52qiBspoKxwxho0fOwe%2FTk%2FvBw%2B0ynuQ%3D%3D';
    const queryParams = '?' + encodeURIComponent('serviceKey') + '=' + serviceKey
        + '&' + encodeURIComponent('routeId') + '=' + encodeURIComponent(routeId);

    // 즉시 API 호출
    request({
        url: url + queryParams,
        method: 'GET'
    }, function (error, response, body) {
        if (error) {
            console.error('버스 정보 업데이트 실패:', error);
            ecallback('버스 정보를 가져오는데 실패했습니다');
            return;
        }

        const parser = new xml2js2.Parser({ explicitArray: false });
        parser.parseString(body, (err, result) => {
            if (err) {
                console.error('XML 파싱 오류:', err);
                ecallback('데이터 처리 중 오류가 발생했습니다');
                return;
            }

            try {
                if (result && result.response && result.response.msgBody) {
                    // 데이터 저장
                    bus.currentData = result.response.msgBody.busLocationList;
                    bus.lastUpdate = new Date();

                    // 주기적 업데이트가 설정되지 않았다면 설정
                    if (!bus.updateInterval) {
                        bus.updateInterval = setInterval(() => {
                            mybusinfo(routeId, () => {
                                console.log('버스 정보 자동 업데이트 완료');
                            }, (error) => {
                                console.error('자동 업데이트 실패:', error);
                            });
                        }, 30000); // 30초마다 업데이트
                    }

                    // 성공 응답
                    callback({
                        ok: true,
                        data: bus.currentData,
                        lastUpdate: bus.lastUpdate
                    });
                } else {
                    ecallback('버스 정보가 없습니다');
                }
            } catch (e) {
                console.error('데이터 처리 오류:', e);
                ecallback('데이터 처리 중 오류가 발생했습니다');
            }
        });
    });
}
// API 엔드포인트에서 사용할 함수



module.exports = {
    login,getMID, setSession, getSession, setSession2, getSession2, getUserInfo, getSession3, mybusinfo, getUserSession
};
