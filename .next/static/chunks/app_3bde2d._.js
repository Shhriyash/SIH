(globalThis.TURBOPACK = globalThis.TURBOPACK || []).push(["static/chunks/app_3bde2d._.js", {

"[project]/app/components/GoogleMap.js [app-client] (ecmascript)": ((__turbopack_context__) => {
"use strict";

var { r: __turbopack_require__, f: __turbopack_module_context__, i: __turbopack_import__, s: __turbopack_esm__, v: __turbopack_export_value__, n: __turbopack_export_namespace__, c: __turbopack_cache__, M: __turbopack_modules__, l: __turbopack_load__, j: __turbopack_dynamic__, P: __turbopack_resolve_absolute_path__, U: __turbopack_relative_url__, R: __turbopack_resolve_module_id_path__, b: __turbopack_worker_blob_url__, g: global, __dirname, k: __turbopack_refresh__, m: module, z: require } = __turbopack_context__;
{
__turbopack_esm__({
    "default": (()=>GoogleMap)
});
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_import__("[project]/node_modules/next/dist/compiled/react/jsx-dev-runtime.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_import__("[project]/node_modules/next/dist/compiled/react/index.js [app-client] (ecmascript)");
;
var _s = __turbopack_refresh__.signature();
'use client';
;
function GoogleMap({ apiKey }) {
    _s();
    const mapRef = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])(null);
    const [userLocation, setUserLocation] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(null);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "GoogleMap.useEffect": ()=>{
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition({
                    "GoogleMap.useEffect": (position)=>{
                        setUserLocation({
                            lat: position.coords.latitude,
                            lng: position.coords.longitude
                        });
                    }
                }["GoogleMap.useEffect"], {
                    "GoogleMap.useEffect": (error)=>{
                        console.error("Error getting user location:", error);
                    }
                }["GoogleMap.useEffect"]);
            } else {
                console.error("Geolocation is not supported by this browser.");
            }
        }
    }["GoogleMap.useEffect"], []);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "GoogleMap.useEffect": ()=>{
            if (userLocation && mapRef.current) {
                const script = document.createElement('script');
                script.src = `https://maps.googleapis.com/maps/api/js?key=AIzaSyCKaombiYOuj6morYry2-Ff2RqL3Q0E1sI&libraries=places`;
                script.async = true;
                script.onload = initMap;
                document.head.appendChild(script);
                return ({
                    "GoogleMap.useEffect": ()=>{
                        document.head.removeChild(script);
                    }
                })["GoogleMap.useEffect"];
            }
        }
    }["GoogleMap.useEffect"], [
        apiKey,
        userLocation
    ]);
    function initMap() {
        const map = new google.maps.Map(mapRef.current, {
            center: userLocation,
            zoom: 14
        });
        const service = new google.maps.places.PlacesService(map);
        service.nearbySearch({
            location: userLocation,
            radius: 5000,
            type: [
                'post_office'
            ]
        }, (results, status)=>{
            if (status === google.maps.places.PlacesServiceStatus.OK) {
                for(let i = 0; i < results.length; i++){
                    createMarker(results[i], map);
                }
            }
        });
    }
    function createMarker(place, map) {
        const marker = new google.maps.Marker({
            map: map,
            position: place.geometry.location
        });
        google.maps.event.addListener(marker, 'click', ()=>{
            const infowindow = new google.maps.InfoWindow();
            infowindow.setContent(place.name);
            infowindow.open(map, marker);
        });
    }
    if (!userLocation) {
        return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
            className: "h-full flex items-center justify-center",
            children: "Loading map..."
        }, void 0, false, {
            fileName: "[project]/app/components/GoogleMap.js",
            lineNumber: 78,
            columnNumber: 12
        }, this);
    }
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        ref: mapRef,
        className: "w-full h-full"
    }, void 0, false, {
        fileName: "[project]/app/components/GoogleMap.js",
        lineNumber: 81,
        columnNumber: 10
    }, this);
}
_s(GoogleMap, "AhAOUzUK/CeVETouf0Hz7Gw/6dU=");
_c = GoogleMap;
var _c;
__turbopack_refresh__.register(_c, "GoogleMap");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_refresh__.registerExports(module, globalThis.$RefreshHelpers$);
}
}}),
"[project]/app/page.js [app-rsc] (ecmascript, Next.js server component, client modules)": ((__turbopack_context__) => {

var { r: __turbopack_require__, f: __turbopack_module_context__, i: __turbopack_import__, s: __turbopack_esm__, v: __turbopack_export_value__, n: __turbopack_export_namespace__, c: __turbopack_cache__, M: __turbopack_modules__, l: __turbopack_load__, j: __turbopack_dynamic__, P: __turbopack_resolve_absolute_path__, U: __turbopack_relative_url__, R: __turbopack_resolve_module_id_path__, b: __turbopack_worker_blob_url__, g: global, __dirname, t: require } = __turbopack_context__;
{
}}),
}]);

//# sourceMappingURL=app_3bde2d._.js.map