fun main(args: Array<String>){
    var age: Int
    var lage: Long
    var dweight: Double
    var weight: Float
    var z: Int
    
    age = 23
    println(age)
    
    age = 25
    println(age)
    
    lage = 45L
    println(lage)
    
    dweight = 100.15
    println(dweight)
    
    weight = 81.35F
    println(weight)
    
    val text: String = "Bla, Bla! Bla, Bla!"
    println(text)
    
    var txt: String = "$text length is ${text.length} symbols"
    println(txt)
    
    z = 4 shr 1
    println(z)
    
    var range1 = 'a'..'d'
    
    for (c in range1) print(c)
    println()
    
    var numbers: IntArray = IntArray(6, {5})
    
    for(i: Int in numbers.indices) {
        numbers[i] = i
        print(numbers[i])
    }
    
}
    