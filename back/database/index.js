require('dotenv').config();
const serviceKey = process.env.API_KEY;
const xml2js2 = require('xml2js');
const session=[];
const bus = {
    lastUpdate: null,
    currentData: null,
    updateInterval: null,
    routeId: null,
    routeName: null,
    stationId: null,
    staOrder: null,
    predictTime1: null,
    predictTime2: null,
    remainSeatCnt1: null,
    remainSeatCnt2: null,

    
};
const busRouteMap = {
    "200000103": "9",
    "234000016": "1112",
    "233000132": "1560A",
    "200000115": "5100",
    "200000112": "7000",
    "234001243": "M5107"

};
const stationMap = {
    "228001174": "사색의광장(정문행)",
    "228000704": "생명과학대.산업대학(정문행)",
    "228000703": "경희대체육대학.외대(정문행)",
    "203000125": "경희대학교(정문행)",
    "228000723": "경희대정문(사색행)",
    "203000037": "경희대정문(사색행)",
    "228000710": "외국어대학(사색행)",
    "228000709": "생명과학대(사색행)",
    "228000708": "사색의광장(사색행)",
    "228000706": "경희대차고지(1)",
    "228000707": "경희대차고지(2)"


};
const busArrival = {
    lastUpdate: null,
    currentData: {},  // stopId를 키로 사용
    updateIntervals: {}  // 각 정류장별 인터벌 저장
};

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

function mybusinfo(routeId, callback, ecallback) {
    const url = 'http://apis.data.go.kr/6410000/buslocationservice/getBusLocationList';
    const queryParams = '?' + encodeURIComponent('serviceKey') + '=' + serviceKey
        + '&' + encodeURIComponent('routeId') + '=' + encodeURIComponent(routeId);

    request({
        url: url + queryParams,
        method: 'GET'
    }, function (error, response, body) {
        if (error) {
            console.error('버스 위치 정보 조회 실패:', error);
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
                    const busData = result.response.msgBody.busLocationList;
                    
                    // 버스 정보 가공
                    const processedData = Array.isArray(busData) 
                        ? busData.map(bus => ({
                            routeId: bus.routeId,
                            routeName: busRouteMap[bus.routeId] || bus.routeName,
                            stationId: bus.stationId,
                            stationSeq: bus.stationSeq,
                            endBus: bus.endBus,
                            lowPlate: bus.lowPlate,
                            plateNo: bus.plateNo,
                            remainSeatCnt: bus.remainSeatCnt
                        }))
                        : [];

                    callback({
                        ok: true,
                        data: processedData,
                        lastUpdate: new Date()
                    });
                } else {
                    ecallback('운행 중인 버스가 없습니다');
                }
            } catch (e) {
                console.error('데이터 처리 오류:', e);
                ecallback('데이터 처리 중 오류가 발생했습니다');
            }
        });
    });
}

// API 엔드포인트에서 사용할 함수
function getBusArrival(stationId, callback, ecallback) {
    const url = 'http://apis.data.go.kr/6410000/busarrivalservice/getBusArrivalList';
    const queryParams = '?' + encodeURIComponent('serviceKey') + '=' + serviceKey
        + '&' + encodeURIComponent('stationId') + '=' + encodeURIComponent(stationId);

    request({
        url: url + queryParams,
        method: 'GET'
    }, function (error, response, body) {
        if (error) {
            console.error('API 요청 실패:', error);
            ecallback('도착 정보를 가져오는데 실패했습니다');
            return;
        }

        // API 응답 상태 코드 확인
        if (response.statusCode !== 200) {
            console.error('API 응답 오류:', response.statusCode, body);
            ecallback('API 서버 오류가 발생했습니다');
            return;
        }

        const parser = new xml2js2.Parser({ explicitArray: false });
        parser.parseString(body, (err, result) => {
            if (err) {
                console.error('XML 파싱 오류:', err, 'Raw body:', body);
                ecallback('데이터 처리 중 오류가 발생했습니다');
                return;
            }

            try {
                // result 객체 구조 로깅
                console.log('API 응답 구조:', JSON.stringify(result, null, 2));

                if (!result || !result.response) {
                    console.error('잘못된 응답 형식:', result);
                    ecallback('API 응답 형식이 올바르지 않습니다');
                    return;
                }

                // 정류장 ID가 유효하지 않은 경우
                if (result.response.msgHeader?.resultCode !== '0') {
                    console.error('API 오류 코드:', result.response.msgHeader);
                    ecallback('유효하지 않은 정류장입니다');
                    return;
                }

                // 정상 응답이지만 도착 예정 버스가 없는 경우
                if (!result.response.msgBody?.busArrivalList) {
                    callback({
                        ok: true,
                        data: [],
                        message: '도착 예정 버스가 없습니다',
                        lastUpdate: new Date()
                    });
                    return;
                }

                const arrivalData = result.response.msgBody.busArrivalList;
                let processedData;
                if (Array.isArray(arrivalData)) {
                    processedData = arrivalData.map(bus => ({
                        routeId: bus.routeId,
                        routeName: busRouteMap[bus.routeId],
                        predictTime1: bus.predictTime1,
                        predictTime2: bus.predictTime2,
                        remainSeatCnt1: bus.remainSeatCnt1,
                        remainSeatCnt2: bus.remainSeatCnt2,
                        staOrder: bus.staOrder,
                        stationId: stationId,
                        stationName: stationMap[stationId]
                    }));
                } else {
                    // 단일 객체인 경우 배열로 변환
                    processedData = [{
                        routeId: arrivalData.routeId,
                        routeName: busRouteMap[arrivalData.routeId],
                        predictTime1: arrivalData.predictTime1,
                        predictTime2: arrivalData.predictTime2,
                        remainSeatCnt1: arrivalData.remainSeatCnt1,
                        remainSeatCnt2: arrivalData.remainSeatCnt2,
                        staOrder: arrivalData.staOrder,
                        stationId: stationId,
                        stationName: stationMap[stationId]
                    }];
                }
        
                callback({
                    ok: true,
                    data: processedData,
                    lastUpdate: new Date()
                });
            } catch (e) {
                console.error('데이터 처리 오류:', e.message, e.stack);
                console.error('처리 중이던 데이터:', result);
                ecallback('데이터 처리 중 오류가 발생했습니다');
            }
        });
    });
}
//DB 저장용 함수
function getBusArrival2(stationId, callback, ecallback) {
    const url = 'http://apis.data.go.kr/6410000/busarrivalservice/getBusArrivalList';
    const queryParams = '?' + encodeURIComponent('serviceKey') + '=' + serviceKey
        + '&' + encodeURIComponent('stationId') + '=' + encodeURIComponent(stationId);

    request({
        url: url + queryParams,
        method: 'GET'
    }, function (error, response, body) {
        if (error) {
            console.error('정류장 도착 정보 조회 실패:', error);
            ecallback('도착 정보를 가져오는데 실패했습니다');
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
                    const arrivalData = result.response.msgBody.busArrivalList;
                    
                    // 도착 정보 가공
                    const processedData = Array.isArray(arrivalData) 
                        ? arrivalData.map(bus => ({
                            routeId: bus.routeId,
                            routeName: busRouteMap[bus.routeId],
                            predictTime1: bus.predictTime1,
                            predictTime2: bus.predictTime2,
                            remainSeatCnt1: bus.remainSeatCnt1,
                            remainSeatCnt2: bus.remainSeatCnt2,
                            staOrder: bus.staOrder,
                            stationId: stationId
                        }))
                        : [];

                    // 데이터 저장
                    busArrival.currentData[stationId] = processedData;
                    busArrival.lastUpdate = new Date();

                    // 주기적 업데이트 설정 (아직 없는 경우)
                    if (!busArrival.updateIntervals[stationId]) {
                        busArrival.updateIntervals[stationId] = setInterval(() => {
                            getBusArrival(stationId, 
                                () => {
                                    console.log(`정류장 ${stationId} 도착 정보 자동 업데이트 완료`);
                                }, 
                                (error) => {
                                    console.error(`정류장 ${stationId} 자동 업데이트 실패:`, error);
                                }
                            );
                        }, 30000); // 30초마다 업데이트
                    }

                    callback({
                        ok: true,
                        data: processedData,
                        lastUpdate: busArrival.lastUpdate
                    });
                } else {
                    ecallback('도착 예정 버스가 없습니다');
                }
            } catch (e) {
                console.error('데이터 처리 오류:', e);
                ecallback('데이터 처리 중 오류가 발생했습니다');
            }
        });
    });
}


function getBusName(routeId, callback, ecallback) {
    const routeName = busRouteMap[routeId];
    if (routeName) {
        callback({
            ok: true,
            routeId: routeId,
            routeName: routeName
        });
    } else {
        ecallback('해당 노선 정보가 없습니다');
    }
}


module.exports = {
    login,getMID, setSession, getSession, setSession2, getSession2, getUserInfo, getSession3, mybusinfo, getUserSession, getBusArrival, getBusName
};



/*function mybusinfo(routeId, callback, ecallback) {
    const url = 'http://apis.data.go.kr/6410000/buslocationservice/getBusLocationList';
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
}*/