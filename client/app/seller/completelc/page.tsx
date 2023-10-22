"use client";

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { getLCContractAddress } from "@/lib/consts";
import { Loader, RocketIcon } from "lucide-react";
import { useContractWrite, useNetwork, usePublicClient } from "wagmi";
import LCContractABI from "@/contracts/LCContract.json";
import { useToast } from "@/components/ui/use-toast";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { useState } from "react";

const formSchema = z.object({
  address: z.string({
    required_error: "Please enter address.",
  }),
});

export default function SellerCompleteLC() {
  const { chain } = useNetwork();

  const publicClient = usePublicClient();

  const [isCompleting, setIsCompleting] = useState(false);

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      // ************************************ //
      // TESTING
      ...(process.env.NODE_ENV === "development"
        ? {
            address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            // address: "0xE0e05d4f780D768eb4761581256c1E18808C362d",
          }
        : {}),
    },
  });

  const address = form.watch("address");

  const {
    data: completeLCData,
    isLoading: isCompleteLCLoading,
    isSuccess: isCompleteLCSuccess,
    isError: isCompleteLCError,
    error: completeLCError,
    writeAsync: completeLCAsync,
  } = useContractWrite({
    address: getLCContractAddress(chain?.id),
    abi: LCContractABI.abi, // TODO: fix type
    functionName: "completeLC",
  });

  const { toast } = useToast();

  const onCompleteLCClick = async () => {
    setIsCompleting(false);

    // Complete LC
    const a = [0, 0];
    const b = [
      [0, 0],
      [0, 0],
    ];
    const c = [0, 0];
    const siganls = [BigInt(address), 0, 0, 0, 0, 0, 0, 0, 0, 0];

    try {
      const tx = await completeLCAsync({
        args: [a, b, c, siganls],
      });

      await publicClient.waitForTransactionReceipt({
        hash: tx.hash,
      });

      if (isCompleteLCSuccess) {
        toast({
          title: "LC Completed",
          variant: "success",
        });
      }

      if (isCompleteLCError) {
        toast({
          title: "Failed to Complete LC",
          description: completeLCError?.message,
          variant: "destructive",
        });
      }
    } catch (err) {
      toast({
        title: "Failed to Complete LC",
        description: (err as any)?.message,
        variant: "destructive",
      });
    }

    setIsCompleting(true);
  };

  return (
    <div className="flex flex-col gap-4 mx-auto mt-16 max-w-[800px] w-full">
      <h4 className="font-bold text-foreground text-2xl">Complete LC</h4>

      <div>
        <Form {...form}>
          <form
            onSubmit={form.handleSubmit(() => {})}
            className="flex gap-4 items-end"
          >
            <FormField
              control={form.control}
              name="address"
              render={({ field }) => (
                <FormItem className="flex-1">
                  <FormLabel>Applicant's ETH address</FormLabel>
                  <FormControl>
                    <Input placeholder="" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <Button type="submit">Submit</Button>
          </form>
        </Form>
      </div>

      <div className="flex flex-col gap-2 w-full mt-4">
        <Label>Email</Label>
        <Textarea className="h-[300px]" placeholder="" />
      </div>

      {/* {!isErrorOREmptyData && !isLoading ? ( */}
      <Button
        className="w-full"
        size="lg"
        onClick={onCompleteLCClick}
        disabled={isCompleting || isCompleteLCSuccess}
      >
        {!isCompleting ? (
          "Complete LC"
        ) : (
          <>
            <Loader className="animate-spin" />
          </>
        )}
      </Button>
      {/* ) : null} */}

      {isCompleteLCSuccess && !isCompleting ? (
        <Alert variant="success">
          <RocketIcon className="h-4 w-4" />
          <AlertTitle>LC Completed!</AlertTitle>
          <AlertDescription>LC has been completed</AlertDescription>
        </Alert>
      ) : null}
    </div>
  );
}
