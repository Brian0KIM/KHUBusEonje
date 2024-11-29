const fs = require('fs');
const path = require('path');
require('dotenv').config();//환경변수 설정
const serviceKey = process.env.API_KEY;
const xml2js2 = require('xml2js');
const JSEncrypt = require('node-jsencrypt');
const request = require('request');
const fs2 = require('fs').promises;
const { DateTime } = require('luxon');
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
    "200000115": "5100",
    "200000112": "7000",
    "234001243": "M5107",
    "234000884": "1560A",
    "228000433": "1560B"

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
    "228000707": "경희대차고지(2)"
    //"203000037": "경희대정문(사색행)" 


};
const busArrival = {
    lastUpdate: null,
    currentData: {},  // stopId를 키로 사용
    updateIntervals: {}  // 각 정류장별 인터벌 저장
};
const specialRouteMapping={
    "228000710": {  // 외국어대학(사색행)
        "234001243": {  // M5107
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 1,
            staOrderOffset: 1  
        },
        "234000884": {  // 1560A
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 1,
            staOrderOffset: 1  
        },
        "228000433": {  // 1560B
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 1,
            staOrderOffset: 1  
        }
    },
    "228000709": {  // 생명과학대(사색행)
        "234001243": {  // M5107
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 2,// 도착 예정 시간에 더할 시간(분)
            staOrderOffset: 2  //정류장 순서에 더할 값
        },
        "234000884": {  // 1560A
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 2,
            staOrderOffset: 2 
        },
        "228000433": {  // 1560B
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 2,
            staOrderOffset: 2 
        }
    },
    "228000708": {  // 사색의광장(사색행)
        "234001243": {  // M5107
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 3,
            staOrderOffset: 3  
        },
        "234000884": {  // 1560A
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 3,
            staOrderOffset: 3  
        },
        "228000433": {  // 1560B
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 3,
            staOrderOffset: 3  
        }

    }
};

const specialRouteMappingFullPath = {
    "228000710": {  // 외국어대학(사색행)
        "234001243": {  // M5107
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 1,
            staOrderOffset: 1  
        },
        "234000884": {  // 1560A
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 1,
            staOrderOffset: 1  
        },
        "228000433": {  // 1560B
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 1,
            staOrderOffset: 1  
        }
    },
    "228000709": {  // 생명과학대(사색행)
        "234001243": {  // M5107
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 2,// 도착 예정 시간에 더할 시간(분)
            staOrderOffset: 2  //정류장 순서에 더할 값
        },
        "234000884": {  // 1560A
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 2,
            staOrderOffset: 2 
        },
        "228000433": {  // 1560B
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 2,
            staOrderOffset: 2 
        }
    },
    
    "228000708": {  // 사색의광장(사색행)
        "234001243": {  // M5107
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 3,
            staOrderOffset: 3  
        },
        "234000884": {  // 1560A
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 3,
            staOrderOffset: 3  
        },
        "228000433": {  // 1560B
            referenceStationId: "228000723",  // 경희대정문(사색행)
            timeOffset: 3,
            staOrderOffset: 3  
        }

    },
    "228001174": {  // 사색의광장(정문행)
        "234001243": {  // M5107
            referenceStationId: "203000125",  // 경희대학교(정문행)
            timeOffset: -3,
            staOrderOffset: -3  
        },
        "234000884": {  // 1560A
            referenceStationId: "203000125",  // 경희대학교(정문행)
            timeOffset: -3,
            staOrderOffset: -3  
        },
        "228000433": {  // 1560B
            referenceStationId: "203000125",  // 경희대학교(정문행)
            timeOffset: -3,
            staOrderOffset: -3  
        }
    },
    "228000704": {  // 생명과학대.산업대학(정문행)
        "234001243": {  // M5107
            referenceStationId: "203000125",  // 경희대학교(정문행)
            timeOffset: -2,
            staOrderOffset: -2  
        },
        "234000884": {  // 1560A
            referenceStationId: "203000125",  // 경희대학교(정문행)
            timeOffset: -2,
            staOrderOffset: -2  
        },
        "228000433": {  // 1560B
            referenceStationId: "203000125",  // 경희대학교(정문행)
            timeOffset: -2,
            staOrderOffset: -2  
        }
    },
    "228000703": {  // 경희대체육대학.외대(정문행)
        "234001243": {  // M5107
            referenceStationId: "203000125",  // 경희대학교(정문행)
            timeOffset: -1,
            staOrderOffset: -1  
        },
        "234000884": {  // 1560A
            referenceStationId: "203000125",  // 경희대학교(정문행)
            timeOffset: -1,
            staOrderOffset: -1  
        },
        "228000433": {  // 1560B
            referenceStationId: "203000125",  // 경희대학교(정문행)
            timeOffset: -1,
            staOrderOffset: -1  
        }
    }
};
const stationRouteOrder = {
    "228001174":{//사색의광장(정문행)
        "200000103": "1",//9번 
        "200000115": "1",//5100
        "200000112": "1",//7000
        "234001243": "1",//M5107
        "234000884": "1",//1560A
        "234000016": "1",//1112
        "228000433": "1",//1560B
    },
    "228000704":{//생명과학대.산업대학(정문행)
        "200000103": "2",//9번 
        "200000115": "2",//5100
        "200000112": "2",//7000
        "234001243": "2",//M5107
        "234000884": "2",//1560A
        "234000016": "2",//1112
        "228000433": "2",//1560B
    },
    "228000703":{//경희대체육대학.외대(정문행)
        "200000103": "3",//9번 
        "200000115": "3",//5100
        "200000112": "3",//7000
        "234001243": "3",//M5107
        "234000884": "3",//1560A
        "234000016": "3",//1112
        "228000433": "3",//1560B
    },
    "203000125":{//경희대학교(정문행)
        "200000103": "4",//9번 
        "200000115": "4",//5100
        "200000112": "4",//7000
        "234001243": "4",//M5107
        "234000884": "4",//1560A
        "234000016": "4",//1112
        "228000433": "4",//1560B
    },
    "228000723":{//경희대정문(사색행)
        "200000103": "87",//9번 
        "200000115": "56",//5100
        "200000112": "76",//7000
        "234001243": "60",//M5107
        "234000884": "99",//1560A
        "234000016": "68",//1112
        "228000433": "99",//1560B
    },
    "228000710":{//외국어대학(사색행)
        "200000103": "88",//9번 
        "200000115": "57",//5100
        "200000112": "77",//7000
        "234001243": "61",//M5107
        "234000884": "100",//1560A
        "234000016": "69",//1112
        "228000433": "100",//1560B
    },
    "228000709":{//생명과학대(사색행)
        "200000103": "89",//9번 
        "200000115": "58",//5100
        "200000112": "78",//7000
        "234001243": "62",//M5107
        "234000884": "101",//1560A
        "234000016": "70",//1112
        "228000433": "101",//1560B
    },
    "228000708":{//사색의광장(사색행)
        "200000103": "90",//9번 
        "200000115": "59",//5100
        "200000112": "79",//7000
        "234001243": "63",//M5107
        "234000884": "102",//1560A
        "234000016": "71",//1112
        "228000433": "102",//1560B
    }
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



function getpublickey(callback) {
    request.get({uri:'https://lib.khu.ac.kr/login'}, function(err, res, body) {
        const cookie = res.headers['set-cookie']

        let data = body.split("encrypt.setPublicKey('")[1]
        data = data.split("'")[0]
        callback(data, cookie)
    })
}



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
const logout = function(id, cookie, callback, ecallback) {
    try {
        // 세션 배열에서 해당 사용자 정보 찾기
        const sessionIndex = session.findIndex(user => user.id === id);
        
        if (sessionIndex !== -1) {
            // 세션 배열에서 해당 사용자 정보 삭제
            session.splice(sessionIndex, 1);
            callback();
        } else {
            ecallback('세션 정보를 찾을 수 없습니다');
        }
    } catch (error) {
        console.error('로그아웃 처리 중 오류:', error);
        ecallback('로그아웃 처리 중 오류가 발생했습니다');
    }
}
function mybusinfo(routeId, callback, ecallback) {
    const url = 'http://apis.data.go.kr/6410000/buslocationservice/getBusLocationList';
    const queryParams = '?' + encodeURIComponent('serviceKey') + '=' + serviceKey
        + '&' + encodeURIComponent('routeId') + '=' + encodeURIComponent(routeId);
    const currentTime = new Date();
    currentTime.setHours(currentTime.getHours() + 9); 
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
                        lastUpdate: currentTime
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
                const currentTime = new Date();
                currentTime.setHours(currentTime.getHours() + 9);
                // 캐시 업데이트
                busArrival.currentData[stationId] = processedData;
                busArrival.lastUpdate = currentTime;

                callback({
                    ok: true,
                    data: processedData,
                    lastUpdate: currentTime
                });
            } catch (e) {
                console.error('데이터 처리 오류:', e.message, e.stack);
                ecallback('데이터 처리 중 오류가 발생했습니다');
            }
        });
    });
}
//DB 저장용 함수

function findStationName(stationId) {
    // 먼저 stationMap에서 찾기
    if (stationMap[stationId]) {
        return stationMap[stationId];
    }
    
    // stationMap에 없으면 JSON 파일에서 찾기
    const station = busStationData.find(station => station.STTN_ID === stationId);
    return station ? station.STTN_NM_INFO : '알 수 없는 정류장';
}
//---------Monitor Bus Arrival---------
const arrivalPredictions = {
    data: new Map(),  // 데이터 저장
    monitoringInterval: null  // 모니터링 인터벌
};

const MONITORED_STATIONS = ['203000125', '228000723'];

// getBusLocationInfo 함수 - Promise 기반으로 변경
function getBusLocationInfo(stationId) {
    return new Promise((resolve, reject) => {
        const url = 'http://apis.data.go.kr/6410000/busarrivalservice/getBusArrivalList';
        const queryParams = '?' + encodeURIComponent('serviceKey') + '=' + serviceKey
            + '&' + encodeURIComponent('stationId') + '=' + encodeURIComponent(stationId);
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
                resolve(result);
            });
        });
    });
}
async function monitorBusArrivals() {
    for (const stationId of MONITORED_STATIONS) {
        try {
            const result = await getBusLocationInfo(stationId);
            if (!result?.response?.msgBody?.busArrivalList) continue;

            const buses = Array.isArray(result.response.msgBody.busArrivalList) 
                ? result.response.msgBody.busArrivalList 
                : [result.response.msgBody.busArrivalList];

            for (const bus of buses) {
                // busRouteMap에 있는 노선만 처리하고, routeId가 일치하는지 확인
                if (busRouteMap[bus.routeId]) {
                    const currentTime = new Date();
                    currentTime.setHours(currentTime.getHours() + 9);//UTC+9
                    // predictTime1과 plateNo1 처리
                    if (bus.predictTime1 && bus.plateNo1 && parseInt(bus.predictTime1) <= 2) {
                        const key = `${stationId}-${bus.routeId}-${bus.plateNo1}-1`;
                        arrivalPredictions.data.set(key, {
                            stationId,
                            routeId: bus.routeId,  // API에서 받아온 실제 routeId 사용
                            plateNo: bus.plateNo1,
                            predictTime: parseInt(bus.predictTime1),
                            routeName: busRouteMap[bus.routeId],
                            savedTime: currentTime,
                            expectedArrival: new Date(currentTime.getTime() + (parseInt(bus.predictTime1) * 60000)),
                            expiryTime: new Date(currentTime.getTime() + (10 * 60000))
                        });
                        console.log(`버스1 도착 예정 데이터 저장: ${key}, routeId: ${bus.routeId}`);
                    }

                    // predictTime2와 plateNo2 처리
                    if (bus.predictTime2 && bus.plateNo2 && parseInt(bus.predictTime2) <= 2) {
                        const key = `${stationId}-${bus.routeId}-${bus.plateNo2}-2`;
                        arrivalPredictions.data.set(key, {
                            stationId,
                            routeId: bus.routeId,  // API에서 받아온 실제 routeId 사용
                            plateNo: bus.plateNo2,
                            predictTime: parseInt(bus.predictTime2),
                            routeName: busRouteMap[bus.routeId],
                            savedTime: currentTime,
                            expectedArrival: new Date(currentTime.getTime() + (parseInt(bus.predictTime2) * 60000)),
                            expiryTime: new Date(currentTime.getTime() + (10 * 60000))
                        });
                        console.log(`버스2 도착 예정 데이터 저장: ${key}, routeId: ${bus.routeId}`);
                    }
                }
            }
        } catch (error) {
            console.error(`버스 도착 정보 조회 실패 (${stationId}):`, error);
        }
    }

    // 만료된 데이터 제거
    const now = new Date();
    now.setHours(now.getHours() + 9);
    for (const [key, value] of arrivalPredictions.data.entries()) {
        if (value.expiryTime <= now) {
            arrivalPredictions.data.delete(key);
            console.log(`만료된 데이터 제거: ${key}, 시간: ${now.toLocaleString('ko-KR')}`);
        }
    }
}

const MONITORING_INTERVAL = 30000; 

// 모니터링 시작 함수
function startMonitoring() {
    if (!arrivalPredictions.monitoringInterval) {
        console.log('모니터링 시작...');
        
        // 첫 실행
        monitorBusArrivals()
            .then(() => {
                console.log('첫 모니터링 완료');
                console.log('key:',arrivalPredictions.data.keys());
            })
            .catch(error => {
                console.error('모니터링 중 오류:', error);
            });

        // 주기적 실행 설정
        arrivalPredictions.monitoringInterval = setInterval(() => {
            monitorBusArrivals()
                .then(() => {
                    console.log('주기적 모니터링 완료');
                    console.log('key:',arrivalPredictions.data.keys());
                })
                .catch(error => {
                    console.error('주기적 모니터링 중 오류:', error);
                });
        }, MONITORING_INTERVAL);

        console.log('버스 도착 예정 모니터링 시작');
    }
}

// 모니터링 중지 함수
function stopMonitoring() {
    if (arrivalPredictions.monitoringInterval) {
        clearInterval(arrivalPredictions.monitoringInterval);
        arrivalPredictions.monitoringInterval = null;
        console.log('버스 도착 예정 모니터링 중지');
    }
}

// 서버 시작 시 모니터링 시작
//startMonitoring();

// 저장된 데이터 조회 함수
function getStoredPredictions() {
    const predictions = [];
    for (const [key, value] of arrivalPredictions.data.entries()) {
        predictions.push({
            key,
            ...value,
        });
    }
    return predictions;
}



function getStoredPredictionsByStation(stationId) {
    const predictions = [];
    for (const [key, value] of arrivalPredictions.data.entries()) { // O(n)
        if (value.stationId === stationId) {                        // O(1)
            predictions.push({...value});                           // O(1)
        }
    }
    return predictions;
}
//past history
/*function getPastBusArrival(routeId, stationId, staOrder, date) {
    return new Promise((resolve, reject) => {
        const url = 'https://api.gbis.go.kr/ws/rest/pastarrivalservice/json';
        const queryParams = new URLSearchParams({
            serviceKey: gbIsApiKey,  // .env 파일에 GBIS API 키 추가 필요
            sDay: date,                            // YYYY-MM-DD 형식
            routeId: routeId,
            stationId: stationId,
            staOrder: staOrder
        }).toString();

        request({
            url: `${url}?${queryParams}`,
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'User-Agent': 'Mozilla/5.0',
                'Origin': 'https://m.gbis.go.kr',
                'Referer': 'https://m.gbis.go.kr/'
            }
        }, function(error, response, body) {
            if (error) {
                console.error('과거 버스 도착 정보 조회 실패:', error);
                reject(error);
                return;
            }

            try {
                const data = JSON.parse(body);
                resolve({
                    ok: true,
                    data: data,
                    lastUpdate: new Date()
                });
            } catch (e) {
                console.error('데이터 처리 오류:', e);
                reject(e);
            }
        });
    });
}*/
function getStaOrder(stationId, routeId) {
    return stationRouteOrder[stationId]?.[routeId];
}

let lastApiCall = null;
const API_CALL_INTERVAL = 1000; // 5초

// 캐시 파일 경로
const CACHE_FILE_PATH = path.join(__dirname, 'pastBusCache.json');

async function loadCache() {
    try {
        const data = await fs2.readFile(CACHE_FILE_PATH, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        return {};
    }
}

async function saveCache(cache) {
    await fs2.writeFile(CACHE_FILE_PATH, JSON.stringify(cache, null, 2));
}

async function getPastBusArrival(routeId, stationId, staOrder, date, onlySevenDays = false) {
    try {
        const cache = await loadCache();
        const requestDate = DateTime.fromISO(date);
        const cacheKey = `${routeId}-${stationId}-${staOrder}-${date}`;

        if (cache[cacheKey]) {
            return {
                ok: true,
                data: cache[cacheKey],
                source: 'cache'
            };
        }

        const datesToFetch = onlySevenDays 
            ? [-7] 
        : (requestDate.weekday >= 6 ? [-7] : [-1, -2, -7]);
        let allResults = [];
        
        for (const dayOffset of datesToFetch) {
            const targetDate = requestDate.plus({ days: dayOffset }).toFormat('yyyy-MM-dd');
            
            if (lastApiCall) {
                const timeSinceLastCall = Date.now() - lastApiCall;
                if (timeSinceLastCall < API_CALL_INTERVAL) {
                    await new Promise(resolve => setTimeout(resolve, API_CALL_INTERVAL - timeSinceLastCall));
                }
            }

            // specialRouteMappingFullPath 확인
            const specialConfig = specialRouteMappingFullPath[stationId]?.[routeId];
            const actualStationId = specialConfig ? specialConfig.referenceStationId : stationId;
            const actualStaOrder = specialConfig ? (Number(staOrder) - specialConfig.staOrderOffset).toString() : staOrder;

            // 실제 API 호출
            const busArrivalList = await fetchBusHistory(routeId, actualStationId, actualStaOrder, targetDate);
            lastApiCall = Date.now();

            if (busArrivalList && busArrivalList.length > 0) {
                // specialRouteMapping 적용
                const mappedData = applySpecialRouteMapping(busArrivalList, stationId, routeId);
                allResults = allResults.concat(mappedData);
            }
        }

        cache[cacheKey] = allResults;
        await saveCache(cache);

        return {
            ok: true,
            data: allResults,
            source: 'api'
        };

    } catch (error) {
        console.error('과거 버스 기록 조회 실패:', error);
        throw error;
    }
}

function applySpecialRouteMapping(data, stationId, routeId) {
    // specialRouteMappingFullPath 적용 로직
    const mappedData = data.map(item => {
        const specialConfig = specialRouteMappingFullPath[stationId]?.[routeId];
        if (specialConfig) {
            return {
                ...item,
                RArrivalDate: adjustDateTime(item.RArrivalDate, specialConfig.timeOffset),
                arrivalDate: adjustDateTime(item.arrivalDate, specialConfig.timeOffset),
                runSeq: item.runSeq + specialConfig.staOrderOffset,
                isCalculated: true
            };
        }
        return item;
    });
    return mappedData;
}

function adjustDateTime(dateTimeStr, offset) {
    if (!dateTimeStr) return dateTimeStr;
    const dt = DateTime.fromFormat(dateTimeStr, 'yyyy-MM-dd HH:mm');
    return dt.plus({ minutes: offset }).toFormat('yyyy-MM-dd HH:mm');
}

async function fetchBusHistory(routeId, stationId, staOrder, date) {
    const url = 'https://api.gbis.go.kr/ws/rest/pastarrivalservice/json';
    const queryParams = new URLSearchParams({
        serviceKey: process.env.GBIS_API_KEY,
        sDay: date,
        routeId: routeId,
        stationId: stationId,
        staOrder: staOrder
    }).toString();

    return new Promise((resolve, reject) => {
        request({
            url: `${url}?${queryParams}`,
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'User-Agent': 'Mozilla/5.0',
                'Origin': 'https://m.gbis.go.kr',
                'Referer': 'https://m.gbis.go.kr/'
            }
        }, function(error, response, body) {
            if (error) {
                reject(error);
                return;
            }
            try {
                const data = JSON.parse(body);
                // API 응답에서 실제 버스 도착 데이터 추출
                const busArrivalList = data.response?.msgBody?.pastArrivalList || [];
                resolve(busArrivalList);  // 버스 도착 데이터 배열만 반환
            } catch (e) {
                reject(e);
            }
        });
    });
}


module.exports = {
    login,getMID, setSession, getSession, setSession2, getSession2, getUserInfo, getSession3, mybusinfo, getUserSession, getBusArrival, getStoredPredictions, startMonitoring, stopMonitoring, getStoredPredictionsByStation, getPastBusArrival, getStaOrder, stationRouteOrder,busRouteMap,stationMap,logout
};
