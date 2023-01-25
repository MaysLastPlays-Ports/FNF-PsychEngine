class RuntimeShader extends FlxShader {
     public function new(__glFragmentSource:String, __glVertexSource:String) {
         this.__glFragmentSource = __glFragmentSource;
         this.__glVertexSource = __glVertexSource;
         super();
     }
}
