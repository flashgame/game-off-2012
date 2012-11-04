package gremlin.core {
    import flash.display.Stage;
    import flash.display3D.Context3D;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.Program3D;
    import flash.display3D.textures.Texture;
    import flash.display3D.VertexBuffer3D;
    import flash.events.Event;
    import flash.geom.Matrix3D;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    import gremlin.animation.SkeletonManager;
    import gremlin.debug.MemoryStats;
    import gremlin.events.EventDispatcher;
    import gremlin.loading.LoaderManager;
    import gremlin.materials.MaterialManager;
    import gremlin.math.MathConstants;
    import gremlin.math.ProjectionUtils;
    import gremlin.meshes.ModelManager;
    import gremlin.scene.Camera;
    import gremlin.shaders.AutoParams;
    import gremlin.shaders.Shader;
    import gremlin.textures.TextureManager;

    /**
     * ...
     * @author mosowski
     */
    public class Context extends EventDispatcher {
        public var stage:Stage;
        public var ctx3d:Context3D;
        public var stats:MemoryStats;
        public var time:Number;
        public var restorableResources:Vector.<IRestorable>;

        public var loaderMgr:LoaderManager;
        public var textureMgr:TextureManager;
        public var skeletonMgr:SkeletonManager;
        public var modelMgr:ModelManager;
        public var materialMgr:MaterialManager;
        public var autoParams:AutoParams;

        // render state variables
        public var activeShader:Shader;
        public var activeCamera:Camera;

        // utilities
        public var projectionUtils:ProjectionUtils;
        public var mathConstants:MathConstants;

        // used for switching-off vertex streams that are active, but not needed in current call
        // activeVertexStreams remebers also vertex buffer bound to stream
        private var activeVertexStreams:Vector.<VertexBuffer3D>;
        private var neededVertexStreams:Vector.<Boolean>;

        // same as above, except for textur samplers. activeSamplers remembers texture bound to sampler
        private var activeSamplers:Vector.<Texture>;
        private var neededSamplers:Vector.<Boolean>;

        private var activeProgram:Program3D;

        // events constants
        public static const CONTEXT_READY:String = "context_ready";
        public static const CONTEXT_LOST:String = "context_lost";
        public static const ENTER_FRAME:String = "enter_frame";
        public static const RESIZE:String = "resize";

        public function Context(_stage:Stage) {
            stage = _stage;
            stats = new MemoryStats();
            restorableResources = new Vector.<IRestorable>();

            time = getTimer() / 1000;

            loaderMgr = new LoaderManager();
            textureMgr = new TextureManager(this);
            skeletonMgr = new SkeletonManager(this);
            modelMgr = new ModelManager(this);
            materialMgr = new MaterialManager(this);
            autoParams = new AutoParams(this);

            projectionUtils = new ProjectionUtils();
            mathConstants = new MathConstants();

            activeVertexStreams = new Vector.<VertexBuffer3D>(8, true);
            neededVertexStreams = new Vector.<Boolean>(8, true);

            activeSamplers = new Vector.<Texture>(8, true);
            neededSamplers = new Vector.<Boolean>(8, true);

            stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        public function requestContext():void {
            stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContextReady);
            stage.stage3Ds[0].requestContext3D();
        }

        private function onContextReady(e:Event = null):void {
            stage.stage3Ds[0].removeEventListener(Event.CONTEXT3D_CREATE, onContextReady);
            stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContextRecreated);
            stage.addEventListener(Event.RESIZE, onStageResize);

            ctx3d = stage.stage3Ds[0].context3D;
            ctx3d.enableErrorChecking = true;
            configureBackBuffer();
            addListener(CONTEXT_LOST, onContextLost);

            dispatch(CONTEXT_READY);
        }

        private function onContextRecreated(e:Event):void {
            ctx3d = stage.stage3Ds[0].context3D;
            dispatch(CONTEXT_LOST);
        }

        public function onStageResize(e:Event):void {
            configureBackBuffer();
            dispatch(RESIZE);
        }

        public function configureBackBuffer():void {
            ctx3d.configureBackBuffer(stage.stageWidth, stage.stageHeight, 0, true);
            // w*h * (color+depth+stencil)
            stats.frameBufferMemory = stage.stageWidth * stage.stageHeight * (4 + 2 + 1);
        }

        public function addRestorableResource(resource:IRestorable):void {
            restorableResources.push(resource);
        }

        public function onContextLost(params:Object = null):void {
            stats.reset();
            configureBackBuffer();
            for (var i:int = 0; i < restorableResources.length; ++i) {
                restorableResources[i].restore();
            }
        }

        public function onEnterFrame(e:Event):void {
            dispatch(ENTER_FRAME);
        }

        public function createTexture(w:Number, h:Number, fmt:String, rt:Boolean = false):Texture {
            stats.textureMemory += w * h * 4;
            return ctx3d.createTexture(w, h, fmt, rt);
        }

        public function createVertexBuffer(numVertices:int, data32perVertex:int):VertexBuffer3D {
            stats.vertexMemory += numVertices * data32perVertex;
            return ctx3d.createVertexBuffer(numVertices, data32perVertex);
        }

        public function createIndexBuffer(numIndices:int):IndexBuffer3D {
            stats.indexMemory += numIndices * 2;
            return ctx3d.createIndexBuffer(numIndices);
        }

        public function createProgram(vAsm:ByteArray, fAsm:ByteArray):Program3D {
            var program3d:Program3D = ctx3d.createProgram();
            program3d.upload(vAsm, fAsm);
            stats.numPrograms++;
            return program3d;
        }

        public function setProgramConstantFromByteArray(type:String, firstRegister:int, numRegisters:int, data:ByteArray, byteArrayOffset:int):void {
            ctx3d.setProgramConstantsFromByteArray(type, firstRegister, numRegisters, data, byteArrayOffset);
        }

        public function setProgramConstantFromMatrix(type:String, firstRegister:int, data:Matrix3D, transposed:Boolean = true):void {
            ctx3d.setProgramConstantsFromMatrix(type, firstRegister, data, transposed);
        }

        public function setProgramConstantFromVector(type:String, firstRegister:int, data:Vector.<Number>, numRegisters:int = -1):void {
            ctx3d.setProgramConstantsFromVector(type, firstRegister, data, numRegisters);
        }

        public function setVertexBufferAt(streamId:int, vertexBuffer3d:VertexBuffer3D, offset:int, format:String):void {
            if (activeVertexStreams[streamId] != vertexBuffer3d) {
                ctx3d.setVertexBufferAt(streamId, vertexBuffer3d, offset, format);
                activeVertexStreams[streamId] = vertexBuffer3d;
            }
            neededVertexStreams[streamId] = true;
        }

        public function setTextureAt(samplerId:int, texture:Texture):void {
            if (activeSamplers[samplerId] != texture) {
                ctx3d.setTextureAt(samplerId, texture);
                activeSamplers[samplerId] = texture;
            }
            neededSamplers[samplerId] = true;
        }

        public function setProgram(program3d:Program3D):void {
            if (activeProgram != program3d) {
                ctx3d.setProgram(program3d);
                activeProgram = program3d;
            }
            for (var i:int = 0; i < 8; ++i) {
                neededVertexStreams[i] = false;
                neededSamplers[i] = false;
            }
        }

        public function drawTriangles(indexBuffer3d:IndexBuffer3D, offset:int=0, numTriangles:int = -1):void {
            for (var i:int = 0; i < 8; ++i) {
                if (activeVertexStreams[i] != null && !neededVertexStreams[i]) {
                    ctx3d.setVertexBufferAt(i, null);
                    activeVertexStreams[i] = null;
                }
                if (activeSamplers[i] != null && !neededSamplers[i]) {
                    ctx3d.setTextureAt(i, null);
                    activeSamplers[i] = null;
                }
            }
            ctx3d.drawTriangles(indexBuffer3d, offset, numTriangles);
        }

        public function setCamera(camera:Camera):void {
            activeCamera = camera;
            camera.update();
        }

        public function beginFrame():void {
            ctx3d.clear(0.4, 0.2, 0.8);
            autoParams.updateGlobalAutoParamsValues();
            time = getTimer() / 1000;
        }

        public function endFrame():void {
            ctx3d.present();
        }

    }

}