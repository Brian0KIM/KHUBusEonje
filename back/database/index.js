const fs = require('fs');
const path = require('path');
require('dotenv').config();//환경변수 설정
const serviceKey = process.env.API_KEY;
const xml2js2 = require('xml2js');
const session=[];
const bus= {
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
    "228000710": "외국어대학(사색행)",
    "228000709": "생명과학대(사색행)",
    "228000708": "사색의광장(사색행)",
    "228000706": "경희대차고지(1)",
    "228000707": "경희대차고지(2)",
    "203000037": "경희대정문(사색행)"


};
const busArrival = {
    lastUpdate: null,
    currentData: {},  // stopId를 키로 사용
    updateIntervals: {}  // 각 정류장별 인터벌 저장
};
const specialRouteMapping = {
    "228000709": {  // 생명과학대(사색행)
        "234001243": {  // M5107
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 1,// 도착 예정 시간에 더할 시간(분)
            staOrderOffset: 2  //정류장 순서에 더할 값
        },
        "233000132": {  // 1560A
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 1,
            staOrderOffset: 2 
        }
    },
    "228000710": {  // 외국어대학(사색행)
        "234001243": {  // M5107
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 1,
            staOrderOffset: 1  
        },
        "233000132": {  // 1560A
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 1,
            staOrderOffset: 1  
        }
    },
    "228000708": {  // 사색의광장(사색행)
        "234001243": {  // M5107
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 3,
            staOrderOffset: 3  
        },
        "233000132": {  // 1560A
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 3,
            staOrderOffset: 3  
        }
    }
    // 필요한 매핑 추가 가능
};
const busStationData = JSON.parse(
    fs.readFileSync(path.join(__dirname, '버스정류소현황.json'), 'utf8')
);
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
                            stationName: findStationName(bus.stationId),
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
async function getBusArrivalItem(stationId, routeId) {
    return new Promise((resolve, reject) => {
        const url = 'http://apis.data.go.kr/6410000/busarrivalservice/getBusArrivalItem';
        const queryParams = '?' + encodeURIComponent('serviceKey') + '=' + serviceKey
            + '&' + encodeURIComponent('stationId') + '=' + encodeURIComponent(stationId)
            + '&' + encodeURIComponent('routeId') + '=' + encodeURIComponent(routeId);
        request({
            url: url + queryParams,
            method: 'GET'
        }, function (error, response, body) {
            if (error) {
                reject(error);
                return;
            }

            const parser = new xml2js2.Parser({ explicitArray: false });
            parser.parseString(body, (err, result) => {
                if (err) {
                    reject(err);
                    return;
                }
                console.log('getBusArrivalItem 결과:', JSON.stringify(result, null, 2));
                resolve(result);
            });
        });
    });
}
// API 엔드포인트에서 사용할 함수
function getBusArrival(stationId, callback, ecallback) {
    // 특별 처리가 필요한 정류장인지 확인
    const specialRoutes = specialRouteMapping[stationId] || {};

    // 특별 처리가 필요한 노선들의 정보만 가져오기
    const specialBusPromises = Object.entries(specialRoutes).map(async ([routeId, config]) => {
        try {
            const refResult = await getBusArrivalItem(
                config.referenceStationId,
                routeId
            );

            if (refResult.response?.msgBody?.busArrivalItem) {
                const refBus = refResult.response.msgBody.busArrivalItem;
                return {
                    routeId: routeId,
                    routeName: busRouteMap[routeId],
                    predictTime1: String(Number(refBus.predictTime1) + config.timeOffset),
                    predictTime2: String(Number(refBus.predictTime2) + config.timeOffset),
                    remainSeatCnt1: refBus.remainSeatCnt1,
                    remainSeatCnt2: refBus.remainSeatCnt2,
                    staOrder: String(Number(refBus.staOrder) + config.staOrderOffset),
                    locationNo1: String(Number(refBus.locationNo1)+config.staOrderOffset),
                    locationNo2: String(Number(refBus.locationNo2)+config.staOrderOffset),
                    plateNo1: refBus.plateNo1,
                    plateNo2: refBus.plateNo2,
                    stationId: stationId,
                    stationName: stationMap[stationId],
                    isCalculated: true
                };
            }
            return null;
        } catch (e) {
            console.error(`특별 노선 ${routeId} 조회 실패:`, e);
            return null;
        }
    });

    // 일반 버스 정보 가져오기
    const url = 'http://apis.data.go.kr/6410000/busarrivalservice/getBusArrivalList';
    const queryParams = '?' + encodeURIComponent('serviceKey') + '=' + serviceKey
        + '&' + encodeURIComponent('stationId') + '=' + encodeURIComponent(stationId);

    request({
        url: url + queryParams,
        method: 'GET'
    }, async function (error, response, body) {
        if (error) {
            console.error('API 요청 실패:', error);
            ecallback('도착 정보를 가져오는데 실패했습니다');
            return;
        }

        const parser = new xml2js2.Parser({ explicitArray: false });
        parser.parseString(body, async (err, result) => {
            if (err) {
                console.error('XML 파싱 오류:', err);
                ecallback('데이터 처리 중 오류가 발생했습니다');
                return;
            }

            try {
                let processedData = [];

                // 일반 버스 정보 처리 (specialRoutes에 없는 버스들만)
                if (result?.response?.msgBody?.busArrivalList) {
                    const arrivalData = result.response.msgBody.busArrivalList;
                    const normalBuses = Array.isArray(arrivalData) ? arrivalData : [arrivalData];
                    
                    processedData = normalBuses
                        .filter(bus => !specialRoutes[bus.routeId] && busRouteMap[bus.routeId])
                        .map(bus => ({
                            routeId: bus.routeId,
                            routeName: busRouteMap[bus.routeId],
                            predictTime1: bus.predictTime1,
                            predictTime2: bus.predictTime2,
                            remainSeatCnt1: bus.remainSeatCnt1,
                            remainSeatCnt2: bus.remainSeatCnt2,
                            staOrder: bus.staOrder,
                            stationId: stationId,
                            stationName: stationMap[stationId],
                            locationNo1: bus.locationNo1,
                            locationNo2: bus.locationNo2,
                            plateNo1: bus.plateNo1,
                            plateNo2: bus.plateNo2
                        }));
                }

                // 특별 처리 버스 정보 추가
                const specialBuses = (await Promise.all(specialBusPromises))
                    .filter(bus => bus !== null);
                
                processedData = [...processedData, ...specialBuses];

                // 캐시 업데이트
                busArrival.currentData[stationId] = processedData;
                busArrival.lastUpdate = new Date();

                callback({
                    ok: true,
                    data: processedData,
                    lastUpdate: new Date()
                });
            } catch (e) {
                console.error('데이터 처리 오류:', e.message, e.stack);
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

function findStationName(stationId) {
    // 먼저 stationMap에서 찾기
    if (stationMap[stationId]) {
        return stationMap[stationId];
    }
    
    // stationMap에 없으면 JSON 파일에서 찾기
    const station = busStationData.find(station => station.STTN_ID === stationId);
    return station ? station.STTN_NM_INFO : '알 수 없는 정류장';
}

/*function getBusName(routeId, callback, ecallback) {
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
}*/


module.exports = {
    login,getMID, setSession, getSession, setSession2, getSession2, getUserInfo, getSession3, mybusinfo, getUserSession, getBusArrival
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