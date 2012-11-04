package gremlin.shaders {
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.Endian;
    import gremlin.core.Context;
    import gremlin.core.IRestorable;
    import gremlin.shaders.consts.IShaderConst;

    /**
     * ...
     * @author mosowski
     */
    public class ShaderProgram {
        public var ctx:Context;
        public var source:String;
        public var params:Dictionary;
        public var type:String;
        public var autoParams:Vector.<String>;
        public var consts:Dictionary;

        private static const _uploadAux128:ByteArray = new ByteArray();

        {
            _uploadAux128.endian = Endian.LITTLE_ENDIAN;
            _uploadAux128.writeFloat(0);
            _uploadAux128.writeFloat(0);
            _uploadAux128.writeFloat(0);
            _uploadAux128.writeFloat(0);
        }

        public function ShaderProgram(_ctx:Context) {
            ctx = _ctx;
            params = new Dictionary();
            autoParams = new Vector.<String>();
            consts = new Dictionary();
        }

        public function setSource(_source:String):void {
            source = _source;
        }

        public function addParam(name:String, register:int):void {
            params[name] = register;
        }

        public function addAutoParam(name:String, register:int):void {
            addParam(name, register);
            autoParams.push(name);
        }

        public function addConst(name:String, register:int, value:IShaderConst):void {
            addParam(name, register);
            consts[name] = value;
        }

        public function setParamFloat(name:String, x:Number):void {
            if (params[name] != null) {
                _uploadAux128.position = 0;
                _uploadAux128.writeFloat(x);
                ctx.setProgramConstantFromByteArray(type, params[name], 1, _uploadAux128, 0);
            }
        }

        public function setParamVec2(name:String, x:Number, y:Number):void {
            if (params[name] != null) {
                _uploadAux128.position = 0;
                _uploadAux128.writeFloat(x);
                _uploadAux128.writeFloat(y);
                ctx.setProgramConstantFromByteArray(type, params[name], 1, _uploadAux128, 0);
            }
        }

        public function setParamVec3(name:String, x:Number, y:Number, z:Number):void {
            if (params[name] != null) {
                _uploadAux128.position = 0;
                _uploadAux128.writeFloat(x);
                _uploadAux128.writeFloat(y);
                _uploadAux128.writeFloat(z);
                ctx.setProgramConstantFromByteArray(type, params[name], 1, _uploadAux128, 0);
            }
        }

        public function setParamVec4(name:String, x:Number, y:Number, z:Number, w:Number):void {
            if (params[name] != null) {
                _uploadAux128.position = 0;
                _uploadAux128.writeFloat(x);
                _uploadAux128.writeFloat(y);
                _uploadAux128.writeFloat(z);
                _uploadAux128.writeFloat(w);
                ctx.setProgramConstantFromByteArray(type, params[name], 1, _uploadAux128, 0);
            }
        }

        public function setParamByteArray(name:String, data:ByteArray, offset:int = 0):void {
            if (params[name] != null) {
                ctx.setProgramConstantFromByteArray(type, params[name], data.length / 16, data, offset);
            }
        }

        public function setParamVector(name:String, data:Vector.<Number>, numRegisters:int = -1):void {
            if (params[name] != null) {
                ctx.setProgramConstantFromVector(type, params[name], data, numRegisters);
            }
        }

        public function setParamM44(name:String, m44:Matrix3D):void {
            if (params[name] != null) {
                ctx.setProgramConstantFromMatrix(type, params[name], m44);
            }
        }

        public function setParamM44Array(name:String, array:Vector.<Matrix3D>):void {
            if (params[name] != null) {
                var register:int = params[name];
                for (var i:int = 0; i < array.length; ++i) {
                    if (array[i] != null) {
                        ctx.setProgramConstantFromMatrix(type, register + i * 4, array[i]);
                    }
                }
            }
        }

        public function setParamM42(name:String, m42:Matrix):void {
            throw "Not implemented yet."
        }

        public function uploadGlobalAutoParams():void {
            for (var i:int = 0; i < autoParams.length; ++i) {
                var autoParam:IShaderConst = ctx.autoParams.globalAutoParams[autoParams[i]];
                if (autoParam) {
                    autoParam.uploadValue(this, autoParams[i]);
                }
            }
            for (var constName:String in consts) {
                var constVal:IShaderConst = consts[constName];
                constVal.uploadValue(this, constName);
            }
        }

        public function uploadLocalAutoParams():void {
            for (var i:int = 0; i < autoParams.length; ++i) {
                var autoParam:IShaderConst = ctx.autoParams.localAutoParams[autoParams[i]];
                if (autoParam) {
                    autoParam.uploadValue(this, autoParams[i]);
                }
            }
        }

        public function getAssembly():ByteArray {
            var assembler:AGALMiniAssembler = new AGALMiniAssembler();
            assembler.assemble(type, source);
            return assembler.agalcode;
        }
    }

}