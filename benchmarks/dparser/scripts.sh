./make_dparser -o test.c ../../dparser-master/tests/python.test.g 
./make_dparser -o test.c ../../dparser-master/tests/sample.test.g 
./make_dparser -o test.c ../../dparser-master/tests/mcrl2_syntax.test.g 
./make_dparser -o test.c ../../dparser-master/tests/ansic.test.g 
./make_dparser -o test.c ../../dparser-master/tests/bnf.g
DIR=$(pwd;)

cd ../../dparser-master/tests/
 
for value in {1..50}
do
    ${DIR}/make_dparser -o ../../test.c ./g${value}.test.g 
    if [[ $? -ne 0 ]]; then
        echo "error: g${value}.test.g"
        fail=1
    fi
done

if [[ $fail == 1 ]]; then
    exit 1
fi