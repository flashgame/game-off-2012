package gremlin.shaders {
    import flash.utils.Dictionary;
    import gremlin.core.Context;
    import gremlin.shaders.consts.ShaderConstFloat;
    import gremlin.shaders.consts.ShaderConstM44;
    import gremlin.shaders.consts.ShaderConstM44Array;

    /**
     * ...
     * @author mosowski
     */
    public class AutoParams {
        public var ctx:Context;
        //  autoparameters per-pass
        public var globalAutoParams:Dictionary;
        // autoparameters per-renderable
        public var localAutoParams:Dictionary;

        public var cameraMatrix:ShaderConstM44;
        public var viewMatrix:ShaderConstM44;
        public var projectionMatrix:ShaderConstM44;
        public var time:ShaderConstFloat;
        public var modelMatrix:ShaderConstM44;
        public var bonesMatrices:ShaderConstM44Array;

        public static const CAMERA_MATRIX:String = "cameraMatrix";
        public static const VIEW_MATRIX:String = "viewMatrix";
        public static const PROJECTION_MATRIX:String = "projectionMatrix";
        public static const TIME:String = "time";
        public static const MODEL_MATRIX:String = "modelMatrix";
        public static const BONES_MATRICES:String = "bonesMatrices";

        public function AutoParams(_ctx:Context) {
            ctx = _ctx;
            globalAutoParams = new Dictionary();
            localAutoParams = new Dictionary();

            globalAutoParams[CAMERA_MATRIX] = cameraMatrix = new ShaderConstM44();
            globalAutoParams[VIEW_MATRIX] = viewMatrix = new ShaderConstM44();
            globalAutoParams[PROJECTION_MATRIX] = projectionMatrix = new ShaderConstM44();
            globalAutoParams[TIME] = time = new ShaderConstFloat();

            localAutoParams[MODEL_MATRIX] = modelMatrix = new ShaderConstM44();
            localAutoParams[BONES_MATRICES] = bonesMatrices = new ShaderConstM44Array(32);
        }

        public function updateGlobalAutoParamsValues():void {
            cameraMatrix.value = ctx.activeCamera.cameraMatrix;
            viewMatrix.value = ctx.activeCamera.viewMatrix;
            projectionMatrix.value = ctx.activeCamera.projectionMatrix;
            time.value = ctx.time;
        }

        public function isAutoParam(name:String):Boolean {
            return name in globalAutoParams || name in localAutoParams;
        }
    }

}