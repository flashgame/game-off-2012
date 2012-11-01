package gremlin.scene {
    import gremlin.core.Context;
    import gremlin.core.IRenderable;
    import gremlin.materials.Material;
    import gremlin.meshes.Submesh;

    /**
     * ...
     * @author mosowski
     */
    public class SubmeshEntity implements IRenderable {
        public var meshEntity:MeshEntity;
        public var submesh:Submesh;
        public var material:Material;

        public function SubmeshEntity() {
        }

        public function setSubmesh(_submesh:Submesh):void {
            if (material != null) {
                material.removeRenderable(this);
            }
            submesh = _submesh;
            if (submesh != null) {
                material = submesh.material;
                material.addRenderable(this);
            } else {
                material = null;
            }
        }

        public function render(ctx:Context):void {
            ctx.autoParams.modelMatrix.value = meshEntity.node.getTransformationMatrix();
            ctx.activeShader.uploadLocalAutoParams();

            for (var attrName:String in ctx.activeShader.vertexProgram.attrs) {
                ctx.activeShader.vertexProgram.setVertexAttr(attrName, meshEntity.mesh.vertexBuffer);
            }
            ctx.drawTriangles(meshEntity.mesh.indexBuffer.indexBuffer3d, submesh.indexOffset, submesh.numTriangles);
        }
    }

}